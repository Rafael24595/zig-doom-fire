const std = @import("std");

const build = @import("build.zig.zon");

const terminal_kit = @import("terminal_kit");

const kit_time = terminal_kit.time;

const console = terminal_kit.console;

const AllocatorTracer = terminal_kit.allocator.AllocatorTracer;
const RuntimeState = terminal_kit.runtime_state.RuntimeState;
const Printer = terminal_kit.printer.Printer;

const configuration = @import("../configuration/configuration.zig");

const GameState = @import("./game_state.zig").GameState;
const RenderContext = @import("./render_context.zig").RenderContext;

/// Prints diagnostic information about the application, runtime state,
/// memory usage, rendering configuration, and current matrix dimensions.
///
/// Returns an error if memory allocation, time formatting, or printing fails.
pub fn print_debug(
    state: *RuntimeState,
    game_state: *GameState,
    persistent: *AllocatorTracer,
    scratch: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
    context: *RenderContext,
    target_cursor: usize,
) !usize {
    const allocator = scratch.allocator();

    const matrix = context.matrix;

    const cols = matrix.cols_len();
    const rows = matrix.rows_len();
    const area = rows * cols;

    const time = try kit_time.milliseconds_to_time(allocator, state.get_runtime(), null);
    defer allocator.free(time);

    const power_status = if (matrix.status)
        "on"
    else
        "off";

    var max_cursor: usize = 0;

    const header = try printer.format_limited(
        target_cursor,
        cols,
        "{}: {s}",
        .{
            build.name,
            build.version,
        },
    );

    max_cursor = header.max_cursor;

    const memory = try printer.format_limited(
        target_cursor,
        cols,
        "Persistent memory: {d} bytes | " ++
            "Scratch memory: {d} bytes | " ++
            "Paused {any} | " ++
            "FPS: {d}",
        .{
            persistent.bytes(),
            scratch.bytes(),
            state.is_paused(),
            context.counter.get_frame_rate(std.time.ms_per_s),
        },
    );

    max_cursor = @max(max_cursor, memory.max_cursor);

    const runtime_1 = try printer.format_limited(
        target_cursor,
        cols,
        "Seed: {d} | " ++
            "Matrix: {d} | " ++
            "Columns: {d} | " ++
            "Rows: {d} | " ++
            "Intensity: {d}",
        .{
            config.seed,
            area,
            cols,
            rows,
            matrix.intensity_len(),
        },
    );

    max_cursor = @max(max_cursor, runtime_1.max_cursor);

    const runtime_2 = try printer.format_limited(
        target_cursor,
        cols,
        "Speed: {d}ms | " ++
            "Time: {s} | " ++
            "Color: {s} | " ++
            "Symbol: {s} | " ++
            "Power: {s} | " ++
            "Wind: {d} | " ++
            "Oxygen: {d}",
        .{
            state.get_speed(),
            time,
            @tagName(config.theme_color),
            @tagName(config.theme_symbol),
            power_status,
            game_state.get_wind(),
            game_state.get_oxygen(),
        },
    );

    max_cursor = @max(max_cursor, runtime_2.max_cursor);

    try printer.printf(
        "{s}{s}\n" ++
            "{s}{s}\n" ++
            "{s}{s}\n" ++
            "{s}{s}\n",
        .{
            console.CLEAN_LINE,
            header.text,
            console.CLEAN_LINE,
            memory.text,
            console.CLEAN_LINE,
            runtime_1.text,
            console.CLEAN_LINE,
            runtime_2.text,
        },
    );

    return @max(max_cursor, runtime_2.max_cursor);
}

/// Prints the keyboard shortcuts available to control the application.
///
/// Returns an error if printing the controls fails.
pub fn print_controls(
    printer: *Printer,
    context: *RenderContext,
    target_cursor: usize,
) !usize {
    const matrix = context.matrix;
    const cols = matrix.cols_len();

    var max_cursor: usize = 0;

    const app_controls = try printer.format_limited(
        target_cursor,
        cols,
        "Pause: [{s}] | " ++
            "Inc sleep: [{s}] | " ++
            "Dec sleep: [{s}] | " ++
            "On/Off: [{s}] | " ++
            "Inc oxygen: {s} | " ++
            "Dec oxygen: {s} | " ++
            "Inc wind: [{s}] | " ++
            "Dec wind: [{s}] | ",
        .{
            "p, space",
            "+",
            "-",
            "s",
            "w",
            "x",
            "a",
            "d",
        },
    );

    max_cursor = app_controls.max_cursor;

    const trm_controls = try printer.format_limited(
        target_cursor,
        cols,
        "Scroll left: [{s}] | " ++
            "Scroll right: [{s}] | " ++
            "Show debug: [{s}] | " ++
            "Show controls: [{s}] | " ++
            "Exit: [{s}]",
        .{
            ",",
            ".",
            "/",
            "?",
            "q, ctrl+c",
        },
    );

    try printer.printf(
        "\n{s}{s}" ++
            "\n{s}{s}",
        .{
            console.CLEAN_LINE,
            app_controls.text,
            console.CLEAN_LINE,
            trm_controls.text,
        },
    );

    return @max(max_cursor, trm_controls.max_cursor);
}
