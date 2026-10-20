const std = @import("std");

const build = @import("build.zig.zon");

const terminal_kit = @import("terminal_kit");

const kit_time = terminal_kit.time;

const AllocatorTracer = terminal_kit.allocator.AllocatorTracer;
const RuntimeState = terminal_kit.runtime_state.RuntimeState;
const Printer = terminal_kit.printer.Printer;

const configuration = @import("../configuration/configuration.zig");

const FireState = @import("./fire_state.zig").FireState;
const RenderContext = @import("./render_context.zig").RenderContext;

pub fn print_debug(
    state: *RuntimeState,
    fire_state: *FireState,
    persistentAllocator: *AllocatorTracer,
    scratchAllocator: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
    context: *RenderContext,
) !void {
    var scratch = scratchAllocator.allocator();

    var matrix = context.matrix;

    const cols = matrix.cols_len();
    const rows = matrix.rows_len();
    const fixedArea = rows * cols;

    var end_ms = std.time.milliTimestamp();
    if (state.pause.load(.acquire)) {
        end_ms = state.pause_timestamp.load(.acquire);
    }

    const start_timestamp = state.start_timestamp.load(.acquire);

    const time = try kit_time.milliseconds_to_time(scratch, end_ms - start_timestamp, null);
    defer scratch.free(time);

    const paused = state.pause.load(.acquire);

    var power_status: []const u8 = "off";
    if (matrix.status) {
        power_status = "on";
    }

    try printer.printf("{}: {s}\n", .{
        build.name,
        build.version,
    });

    try printer.printf("Persistent memory: {d} bytes | Scratch memory: {d} bytes | Paused {any} | FPS: {d}  \n", .{
        persistentAllocator.bytes(),
        scratchAllocator.bytes(),
        paused,
        context.counter.get_frame_rate(std.time.ms_per_s),
    });

    try printer.printf("Seed: {d} | Matrix: {d} | Columns: {d} | Rows: {d} | Intensity: {d} \n", .{
        config.seed,
        fixedArea,
        cols,
        rows,
        matrix.intensity_len(),
    });

    try printer.printf("Speed: {d}ms | Time: {s} | Color: {s} | Symbol: {s} | Power: {s} | Wind: {d} | Oxygen: {d}  \n", .{
        state.speed_ms.load(.acquire),
        time,
        @tagName(config.theme_color),
        @tagName(config.theme_symbol),
        power_status,
        fire_state.wind.load(.acquire),
        fire_state.oxygen.load(.acquire),
    });
}

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
