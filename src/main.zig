const std = @import("std");
const builtin = @import("builtin");

const terminal_kit = @import("terminal_kit");

const signals = terminal_kit.signals;
const console = terminal_kit.console;
const Printer = terminal_kit.printer.Printer;

const runtime = terminal_kit.runtime_state;

const AllocatorTracer = terminal_kit.allocator.AllocatorTracer;
const MiniLCG = terminal_kit.mini_lcg.MiniLCG;

const PanicHandler = terminal_kit.panic_handler.PanicHandler;

const configuration = @import("configuration/configuration.zig");

const debug = @import("app/debug.zig");

const GameState = @import("app/game_state.zig").GameState;
const RenderContext = @import("app/render_context.zig").RenderContext;

const MatrixPrinter = @import("io/matrix_printer.zig").LinearMatrixPrinter;

const matrix = @import("domain/matrix.zig");
const color = @import("domain/color.zig");

pub const panic = PanicHandler(cleanup_terminal).panic;

fn cleanup_terminal() void {
    console.disable_raw_mode();

    const stdout = std.fs.File.stdout();

    stdout.writeAll(
        console.SHOW_CURSOR ++
            console.CLEAN_ALL ++
            console.RESET_CURSOR,
    ) catch {};
}

/// Initializes application resources, configures the terminal, and starts
/// the rendering loop.
pub fn main() !void {
    var persistent = AllocatorTracer.init(
        std.heap.page_allocator,
    );

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var scratch = AllocatorTracer.init(
        gpa.allocator(),
    );

    var arena = std.heap.ArenaAllocator.init(
        scratch.allocator(),
    );

    defer arena.deinit();

    var printer = Printer{
        .arena = &arena,
        .out = std.fs.File.stdout(),
    };

    defer printer.reset();

    const config = try configuration.from_args(
        persistent.allocator(),
        &printer,
    );

    var state = runtime.RuntimeState{};

    state.start_timestamp.store(config.start_ms, .release);
    state.speed_ms.store(config.milliseconds, .release);

    var game_state = GameState{};

    try console.enable_ansi();
    try console.enable_utf8();

    try console.enable_raw_mode();
    defer console.disable_raw_mode();

    try run(
        &state,
        &game_state,
        &persistent,
        &scratch,
        &config,
        &printer,
    );
}

/// Runs the application session, coordinating input handling and rendering
/// until termination is requested.
pub fn run(
    state: *runtime.RuntimeState,
    game_state: *GameState,
    persistent: *AllocatorTracer,
    scratch: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
) !void {
    try signals.install(state, runtime.on_interrupt);

    defer {
        signals.uninstall() catch |err| {
            std.debug.print("Failed to uninstall signals: {}\n", .{err});
        };
    }

    const allocator = persistent.allocator();

    var lcg = MiniLCG.init(config.seed);

    defer printer.reset();

    try printer.print(console.CLEAN_ALL);
    try printer.print(console.HIDE_CURSOR);

    defer printer.prints(console.SHOW_CURSOR);
    defer printer.prints(console.CLEAN_ALL);

    var input_thread = try std.Thread.spawn(
        .{},
        run_input_loop,
        .{ state, game_state },
    );

    defer input_thread.join();

    while (!runtime.should_exit(state)) {
        _ = state.consume_reload();

        try run_render_cycle(
            allocator,
            persistent,
            scratch,
            state,
            game_state,
            config,
            printer,
            &lcg,
        );
    }
}

inline fn run_render_cycle(
    allocator: std.mem.Allocator,
    persistent: *AllocatorTracer,
    scratch: *AllocatorTracer,
    state: *runtime.RuntimeState,
    game_state: *GameState,
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
        if (game_state.consume_power()) {
            context.matrix.switch_fire();
        }

        try printer.print(console.RESET_CURSOR);

        if (config.debug) {
            try debug.print_debug(
                state,
                game_state,
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
                game_state.wind.load(.acquire),
                game_state.oxygen.load(.acquire),
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

fn run_input_loop(
    state: *runtime.RuntimeState,
    game_state: *GameState,
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
                game_state.request_power();
            },
            'w', 'W' => {
                game_state.mod_oxygen(1);
            },
            'x', 'X' => {
                game_state.mod_oxygen(-1);
            },
            'a', 'A' => {
                game_state.mod_wind(1);
            },
            'd', 'D' => {
                game_state.mod_wind(-1);
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
