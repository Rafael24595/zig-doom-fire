const std = @import("std");
const builtin = @import("builtin");

const AtomicOrder = std.builtin.AtomicOrder;

const build = @import("build.zig.zon");

const configuration = @import("configuration/configuration.zig");

const debug = @import("app/debug.zig");

const utils = @import("commons/utils.zig");
const AllocatorTracer = @import("commons/allocator.zig").AllocatorTracer;
const MiniLCG = @import("commons/mini_lcg.zig").MiniLCG;

const console = @import("io/console.zig");
const Printer = @import("io/printer.zig").Printer;
const MatrixPrinter = @import("io/matrix_printer.zig").LinearMatrixPrinter;

const matrix = @import("domain/matrix.zig");
const color = @import("domain/color.zig");

const wind_default = 0;

var start_timestamp = std.atomic.Value(i64).init(0);

var pause = std.atomic.Value(u8).init(0);
var pause_timestamp = std.atomic.Value(i64).init(0);

var speed_ms = std.atomic.Value(u64).init(0);

var wind = std.atomic.Value(isize).init(wind_default);
var oxygen = std.atomic.Value(isize).init(0);

var exit = std.atomic.Value(u8).init(0);
var power = std.atomic.Value(u8).init(0);

var mutex: std.Thread.Mutex = .{};
var cond: std.Thread.Condition = .{};

pub fn main() !void {
    var basePersistentAllocator = std.heap.page_allocator;
    var persistentAllocator = AllocatorTracer.init(&basePersistentAllocator);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var baseScratchAllocator = gpa.allocator();
    var scratchAllocator = AllocatorTracer.init(&baseScratchAllocator);

    var arena = std.heap.ArenaAllocator.init(scratchAllocator.allocator());
    defer arena.deinit();

    var printer = Printer{
        .arena = &arena,
        .out = std.fs.File.stdout(),
    };

    defer printer.reset();

    const config = try configuration.fromArgs(
        persistentAllocator.allocator(),
        &printer,
    );

    start_timestamp.store(config.start_ms, AtomicOrder.release);
    speed_ms.store(config.milliseconds, AtomicOrder.release);

    try console.enableANSI();
    try console.enableUTF8();
    try console.enableRawMode();

    defer console.disableRawMode();

    try run(
        &persistentAllocator,
        &scratchAllocator,
        &config,
        &printer,
    );
}

pub fn run(persistentAllocator: *AllocatorTracer, scratchAllocator: *AllocatorTracer, config: *const configuration.Configuration, printer: *Printer) !void {
    try defineSignalHandlers();

    var persistent = persistentAllocator.allocator();

    var lcg = MiniLCG.init(config.seed);

    defer printer.reset();

    try printer.print(console.CLEAN_ALL);
    try printer.print(console.HIDE_CURSOR);

    defer printer.prints(console.SHOW_CURSOR);
    defer printer.prints(console.CLEAN_ALL);

    var input_thread = try std.Thread.spawn(
        .{},
        runInputLoop,
        .{},
    );

    defer input_thread.join();

    while (exit.load(AtomicOrder.acquire) == 0) {
        const winsize = try console.winSize();

        const space = calculatePadding(config);

        const area = winsize.cols * winsize.rows;

        const cols = winsize.cols;
        const rows = winsize.rows - space;

        const intensity: usize = calculateIntensity(config, rows);

        const color_manager = try color.ColorManager.init(
            &persistent,
            intensity,
            config.theme_color,
        );

        var mtrx = matrix.LinearMatrix.init(
            &persistent,
            &lcg,
        );

        try mtrx.build(
            cols,
            rows,
            intensity,
        );

        defer mtrx.free();

        var mtrx_printer = try MatrixPrinter.init(
            &persistent,
            printer,
            color_manager,
            config.formatter_matrix,
            config.formatter_cell,
            config.theme_symbol,
            &mtrx,
        );

        defer mtrx_printer.free();

        try printer.print(console.CLEAN_CONSOLE);

        while (exit.load(AtomicOrder.acquire) == 0) {
            if (power.load(AtomicOrder.acquire) == 1) {
                _ = power.fetchXor(1, AtomicOrder.acq_rel);
                mtrx.switch_fire();
            }

            try printer.print(console.RESET_CURSOR);

            if (config.debug) {
                try debug.print_debug(
                    persistentAllocator,
                    scratchAllocator,
                    config,
                    printer,
                    &mtrx,
                    &pause,
                    &pause_timestamp,
                    &start_timestamp,
                    &speed_ms,
                    &wind,
                    &oxygen,
                );
            }

            try mtrx_printer.print(&mtrx);

            if (pause.load(AtomicOrder.acquire) == 0) {
                try mtrx.next(wind.raw, oxygen.raw);
            }

            if (config.controls) {
                try debug.print_controls(printer);
            }

            mutex.lock();
            _ = cond.timedWait(&mutex, speed_ms.raw * std.time.ns_per_ms) catch |err| switch (err) {
                error.Timeout => true,
                else => return err,
            };
            mutex.unlock();

            printer.reset();

            const newWinsize = try console.winSize();
            if (area != newWinsize.cols * newWinsize.rows) {
                break;
            }
        }
    }
}

pub fn calculatePadding(config: *const configuration.Configuration) usize {
    var space: usize = 0;
    if (config.debug) {
        space += 4;
    }

    if (config.controls) {
        space += 1;
    }

    return space;
}

pub fn calculateIntensity(config: *const configuration.Configuration, rows: usize) usize {
    if (config.intensity > 0) {
        return config.intensity;
    }

    const f_rows: f32 = @floatFromInt(rows);
    return @intFromFloat(f_rows * config.intensity_per);
}

fn runInputLoop() !void {
    const stdin = std.fs.File.stdin();

    while (exit.load(AtomicOrder.acquire) == 0) {
        var buf: [1]u8 = undefined;

        const count = try stdin.read(&buf);
        if (count == 0) {
            continue;
        }

        switch (buf[0]) {
            'p', 'P', console.SPACE => {
                const now = std.time.milliTimestamp();
                if (pause.load(AtomicOrder.acquire) == 0) {
                    _ = pause_timestamp.store(now, AtomicOrder.release);
                } else {
                    const diff = now - pause_timestamp.raw;
                    _ = start_timestamp.store(diff + start_timestamp.raw, AtomicOrder.release);
                }

                _ = pause.fetchXor(1, AtomicOrder.acq_rel);
            },
            's', 'S' => {
                _ = power.fetchXor(1, AtomicOrder.acq_rel);
            },
            'w', 'W' => {
                const oxygen_fix = @min(5, oxygen.raw + 1);
                _ = oxygen.store(oxygen_fix, AtomicOrder.release);
            },
            'x', 'X' => {
                const oxygen_fix = @max(-5, oxygen.raw - 1);
                _ = oxygen.store(oxygen_fix, AtomicOrder.release);
            },
            'a', 'A' => {
                const wind_fix = @min(5, wind.raw + 1);
                _ = wind.store(wind_fix, AtomicOrder.release);
            },
            'd', 'D' => {
                const wind_fix = @max(-5, wind.raw - 1);
                _ = wind.store(wind_fix, AtomicOrder.release);
            },
            '+' => {
                const min = @min(1000 * 3, speed_ms.raw + 10);
                _ = speed_ms.store(min, AtomicOrder.release);
                _ = cond.signal();
            },
            '-' => {
                const max = speed_ms.raw -| 10;
                _ = speed_ms.store(max, AtomicOrder.release);
                _ = cond.signal();
            },
            'q', 'Q', console.CTRL_C => {
                _ = exit.fetchXor(1, AtomicOrder.acq_rel);
                _ = cond.signal();
            },
            else => {},
        }
    }
}

pub fn defineSignalHandlers() !void {
    if (builtin.os.tag == .windows) {
        if (std.os.windows.kernel32.SetConsoleCtrlHandler(winCtrlHandler, 1) == 0) {
            return error.FailedToSetCtrlHandler;
        }
        return;
    }

    const action = std.posix.Sigaction{
        .handler = .{ .handler = unixSigintHandler },
        .mask = undefined,
        .flags = 0,
    };

    _ = std.posix.sigaction(std.posix.SIG.INT, &action, null);
}

fn winCtrlHandler(ctrl_type: std.os.windows.DWORD) callconv(.c) std.os.windows.BOOL {
    _ = ctrl_type;
    _ = exit.fetchXor(1, AtomicOrder.acq_rel);
    _ = cond.signal();
    return 1;
}

fn unixSigintHandler(sig_num: i32) callconv(.c) void {
    _ = sig_num;
    _ = exit.fetchXor(1, AtomicOrder.acq_rel);
    _ = cond.signal();
}
