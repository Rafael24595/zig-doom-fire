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

const FireState = @import("app/fire_state.zig").FireState;
const RenderContext = @import("app/render_context.zig").RenderContext;

const MatrixPrinter = @import("io/matrix_printer.zig").LinearMatrixPrinter;

const matrix = @import("domain/matrix.zig");
const color = @import("domain/color.zig");

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

    var fire_state = FireState{};

    try console.enable_ansi();
    try console.enable_utf8();

    try console.enable_raw_mode();
    defer console.disable_raw_mode();

    try run(
        &state,
        &fire_state,
        &persistentAllocator,
        &scratchAllocator,
        &config,
        &printer,
    );
}

pub fn run(
    state: *runtime.RuntimeState,
    fire_state: *FireState,
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
        .{ state, fire_state },
    );

    defer input_thread.join();

    while (!runtime.should_exit(state)) {
        _ = state.consume_reload();

        try run_render_cycle(
            &persistent,
            persistentAllocator,
            scratchAllocator,
            state,
            fire_state,
            config,
            printer,
            &lcg,
        );
    }
}

inline fn run_render_cycle(
    allocator: *std.mem.Allocator,
    persistent: *AllocatorTracer,
    scratch: *AllocatorTracer,
    state: *runtime.RuntimeState,
    fire_state: *FireState,
    config: *const configuration.Configuration,
    printer: *Printer,
    lcg: *MiniLCG,
) !void {
    const winsize = try console.winsize();

    var context: RenderContext = undefined;

    try context.init(
        allocator,
        winsize,
        config,
        printer,
        lcg,
    );
    defer context.deinit();

    try printer.print(console.CLEAN_CONSOLE);

    while (!runtime.should_exit(state) and !runtime.should_reload(state)) {
        if (fire_state.consume_power()) {
            context.matrix.switch_fire();
        }

        try printer.print(console.RESET_CURSOR);

        if (config.debug) {
            try debug.print_debug(
                state,
                fire_state,
                persistent,
                scratch,
                config,
                printer,
                &context,
            );
        }

        try context.matrix_printer.print(&context.matrix);

        if (!state.pause.load(.acquire)) {
            try context.matrix.next(
                fire_state.wind.load(.acquire),
                fire_state.oxygen.load(.acquire),
            );
        }

        if (config.controls) {
            try debug.print_controls(printer);
        }

        const speed = state.speed_ms.load(.acquire);
        try state.wait_for_frame(speed * std.time.ns_per_ms);

        printer.reset();

        if (!winsize.eql(try console.winsize())) {
            state.request_reload();
        }

        context.counter.frame_increment();
    }
}

fn runInputLoop(
    state: *runtime.RuntimeState,
    fire_state: *FireState,
) !void {
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
                fire_state.request_power();
            },
            'w', 'W' => {
                fire_state.mod_oxigen(1);
            },
            'x', 'X' => {
                fire_state.mod_oxigen(-1);
            },
            'a', 'A' => {
                fire_state.mod_wind(1);
            },
            'd', 'D' => {
                fire_state.mod_wind(-1);
            },
            '+' => {
                state.mod_speed(10);
            },
            '-' => {
                state.mod_speed(-10);
            },
            'q', 'Q', console.CTRL_C => {
                state.request_exit();
            },
            else => {},
        }
    }
}
