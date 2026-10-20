const std = @import("std");

const build = @import("build.zig.zon");

const configuration = @import("../configuration/configuration.zig");

const utils = @import("../commons/utils.zig");

const AllocatorTracer = @import("../commons/allocator.zig").AllocatorTracer;
const Printer = @import("../io/printer.zig").Printer;

const matrix = @import("../domain/matrix.zig");

pub fn print_debug(
    persistentAllocator: *AllocatorTracer,
    scratchAllocator: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
    mtrx: *matrix.LinearMatrix,
    pause: *std.atomic.Value(u8),
    pause_timestamp: *std.atomic.Value(i64),
    start_timestamp: *std.atomic.Value(i64),
    speed_ms: *std.atomic.Value(u64),
    wind: *std.atomic.Value(isize),
    oxygen: *std.atomic.Value(isize),
) !void {
    var scratch = scratchAllocator.allocator();

    const cols = mtrx.cols_len();
    const rows = mtrx.rows_len();
    const fixedArea = rows * cols;

    var end_ms = std.time.milliTimestamp();
    if (pause.load(.acquire) == 1) {
        end_ms = pause_timestamp.raw;
    }

    const time = try utils.millisecondsToTime(scratch, end_ms - start_timestamp.raw, null);
    defer scratch.free(time);

    var paused = false;
    if (pause.load(.acquire) == 1) {
        paused = true;
    }

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

    try printer.printf("Speed: {d}ms | Time: {s} | Color: {s} | Symbol: {s} | Power: {s} | Wind: {d} | Oxygen: {d}  \n", .{ speed_ms.raw, time, @tagName(config.theme_color), @tagName(config.theme_symbol), power_status, wind.raw, oxygen.raw });
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
