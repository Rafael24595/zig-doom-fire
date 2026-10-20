const std = @import("std");

const build = @import("build.zig.zon");

const terminal_kit = @import("terminal_kit");

const kit_time = terminal_kit.time;

const AllocatorTracer = terminal_kit.allocator.AllocatorTracer;
const RuntimeState = terminal_kit.runtime_state.RuntimeState;
const Printer = terminal_kit.printer.Printer;

const configuration = @import("../configuration/configuration.zig");

const matrix = @import("../domain/matrix.zig");

pub fn print_debug(
    state: *RuntimeState,
    persistentAllocator: *AllocatorTracer,
    scratchAllocator: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
    mtrx: *matrix.LinearMatrix,
    wind: *std.atomic.Value(isize),
    oxygen: *std.atomic.Value(isize),
) !void {
    var scratch = scratchAllocator.allocator();

    const cols = mtrx.cols_len();
    const rows = mtrx.rows_len();
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
    if (mtrx.status) {
        power_status = "on";
    }

    try printer.printf("{}: {s}\n", .{
        build.name,
        build.version,
    });

    try printer.printf("Persistent memory: {d} bytes | Scratch memory: {d} bytes | Paused {any} \n", .{
        persistentAllocator.bytes(),
        scratchAllocator.bytes(),
        paused,
    });

    try printer.printf("Seed: {d} | Matrix: {d} | Columns: {d} | Rows: {d} | Intensity: {d} \n", .{
        config.seed,
        fixedArea,
        cols,
        rows,
        mtrx.intensity_len(),
    });

    try printer.printf("Speed: {d}ms | Time: {s} | Color: {s} | Symbol: {s} | Power: {s} | Wind: {d} | Oxygen: {d}  \n", .{
        state.speed_ms.load(.acquire),
        time,
        @tagName(config.theme_color),
        @tagName(config.theme_symbol),
        power_status,
        wind.load(.acquire),
        oxygen.load(.acquire),
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
