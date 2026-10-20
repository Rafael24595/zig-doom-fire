const std = @import("std");
const builtin = @import("builtin");

const terminal_kit = @import("terminal_kit");

const signals = terminal_kit.signals;
const console = terminal_kit.console;
const Printer = terminal_kit.printer.Printer;

const runtime = terminal_kit.runtime_state;

const AllocatorTracer = terminal_kit.allocator.AllocatorTracer;
const MiniLCG = terminal_kit.mini_lcg.MiniLCG;

const configuration = @import("configuration/configuration.zig");

const debug = @import("app/debug.zig");

const MatrixPrinter = @import("io/matrix_printer.zig").LinearMatrixPrinter;

const matrix = @import("domain/matrix.zig");
const color = @import("domain/color.zig");

const wind_default = 0;

var wind = std.atomic.Value(isize).init(wind_default);
var oxygen = std.atomic.Value(isize).init(0);
var power = std.atomic.Value(u8).init(0);

pub fn main() !void {
    var persistentAllocator = AllocatorTracer.init(
        std.heap.page_allocator,
    );

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var scratchAllocator = AllocatorTracer.init(
        gpa.allocator(),
    );

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

    var state = runtime.RuntimeState{};

    state.start_timestamp.store(config.start_ms, .release);
    state.speed_ms.store(config.milliseconds, .release);

    try console.enable_ansi();
    try console.enable_utf8();

    try console.enable_raw_mode();
    defer console.disable_raw_mode();

    try run(
        &state,
        &persistentAllocator,
        &scratchAllocator,
        &config,
        &printer,
    );
}

pub fn run(
    state: *runtime.RuntimeState,
    persistentAllocator: *AllocatorTracer,
    scratchAllocator: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
) !void {
    try signals.install(state, runtime.on_interrupt);

    defer {
        signals.uninstall() catch |err| {
            std.debug.print("Failed to uninstall signals: {}\n", .{err});
        };
    }

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
        .{state},
    );

    defer input_thread.join();

    while (!runtime.should_exit(state)) {
        _ = state.consume_reload();

        const winsize = try console.winsize();

        const space = calculatePadding(config);

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

        while (!runtime.should_exit(state) and !runtime.should_reload(state)) {
            if (power.load(.acquire) == 1) {
                _ = power.fetchXor(1, .acq_rel);
                mtrx.switch_fire();
            }

            try printer.print(console.RESET_CURSOR);

            if (config.debug) {
                try debug.print_debug(
                    state,
                    persistentAllocator,
                    scratchAllocator,
                    config,
                    printer,
                    &mtrx,
                    &wind,
                    &oxygen,
                );
            }

            try mtrx_printer.print(&mtrx);

            if (!state.pause.load(.acquire)) {
                try mtrx.next(wind.raw, oxygen.raw);
            }

            if (config.controls) {
                try debug.print_controls(printer);
            }

            const speed = state.speed_ms.load(.acquire);
            try state.wait_for_frame(speed * std.time.ns_per_ms);

            printer.reset();

            const newWinsize = try console.winsize();
            if (winsize.cols != newWinsize.cols or winsize.rows != newWinsize.rows) {
                state.request_reload();
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

fn runInputLoop(state: *runtime.RuntimeState) !void {
    const stdin = std.fs.File.stdin();

    while (!runtime.should_exit(state)) {
        var buf: [1]u8 = undefined;

        const count = try stdin.read(&buf);
        if (count == 0) {
            continue;
        }

        switch (buf[0]) {
            'p', 'P', console.SPACE => {
                state.toggle_pause();
            },
            's', 'S' => {
                _ = power.fetchXor(1, .acq_rel);
            },
            'w', 'W' => {
                const oxygen_fix = @min(5, oxygen.raw + 1);
                _ = oxygen.store(oxygen_fix, .release);
            },
            'x', 'X' => {
                const oxygen_fix = @max(-5, oxygen.raw - 1);
                _ = oxygen.store(oxygen_fix, .release);
            },
            'a', 'A' => {
                const wind_fix = @min(5, wind.raw + 1);
                _ = wind.store(wind_fix, .release);
            },
            'd', 'D' => {
                const wind_fix = @max(-5, wind.raw - 1);
                _ = wind.store(wind_fix, .release);
            },
            '+' => {
                const speed = state.speed_ms.load(.acquire);
                const min = @min(3000, speed + 10);
                state.set_speed(min);
            },
            '-' => {
                const speed = state.speed_ms.load(.acquire);
                const max = speed -| 10;
                state.set_speed(max);
            },
            'q', 'Q', console.CTRL_C => {
                state.request_exit();
            },
            else => {},
        }
    }
}
