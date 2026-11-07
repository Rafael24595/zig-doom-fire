const std = @import("std");

const build = @import("build.zig.zon");

const terminal_kit = @import("terminal_kit");

const kit_time = terminal_kit.time;

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
) !void {
    var allocator = scratch.allocator();

    var matrix = context.matrix;

    const cols = matrix.cols_len();
    const rows = matrix.rows_len();
    const area = rows * cols;

    const time = try kit_time.milliseconds_to_time(allocator, state.get_runtime(), null);
    defer allocator.free(time);

    var power_status: []const u8 = "off";
    if (matrix.status) {
        power_status = "on";
    }

    try printer.printf("{}: {s}\n", .{
        build.name,
        build.version,
    });

    try printer.printf("Persistent memory: {d} bytes | Scratch memory: {d} bytes | Paused {any} | FPS: {d}  \n", .{
        persistent.bytes(),
        scratch.bytes(),
        state.is_paused(),
        context.counter.get_frame_rate(std.time.ms_per_s),
    });

    try printer.printf("Seed: {d} | Matrix: {d} | Columns: {d} | Rows: {d} | Intensity: {d} \n", .{
        config.seed,
        area,
        cols,
        rows,
        matrix.intensity_len(),
    });

    try printer.printf("Speed: {d}ms | Time: {s} | Color: {s} | Symbol: {s} | Power: {s} | Wind: {d} | Oxygen: {d}  \n", .{
        state.get_speed(),
        time,
        @tagName(config.theme_color),
        @tagName(config.theme_symbol),
        power_status,
        game_state.get_wind(),
        game_state.get_oxygen(),
    });
}

/// Prints the keyboard shortcuts available to control the application.
///
/// Returns an error if printing the controls fails.
pub fn print_controls(printer: *Printer) !void {
    try printer.printf("\nPause: [{s}] | On/Off: [{s}] | Inc oxygen: {s} | Dec oxygen: {s} | Inc wind: [{s}] | Dec wind: [{s}] | Inc sleep: [{s}] | Dec sleep: [{s}] | Exit: [{s}]", .{
        "p, space",
        "s",
        "w",
        "x",
        "a",
        "d",
        "+",
        "-",
        "q, ctrl+c",
    });
}
