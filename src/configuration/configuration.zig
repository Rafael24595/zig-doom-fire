const std = @import("std");

const build = @import("build.zig.zon");

const matrix = @import("../domain/matrix.zig");
const symbol = @import("../domain/symbol.zig");
const color = @import("../domain/color.zig");

const Printer = @import("../io/printer.zig").Printer;
const formatter = @import("../io/formatter.zig");

const TypeFormatter = @import("../commons/utils.zig").TypeFormatter;

const Flag = struct {
    flag_short: []const u8,
    flag_long: ?[]const u8 = null,
    type: ?[]const u8 = null,
    desc: []const u8,
    name: []const u8,
    aux_desc: ?[]const u8 = null,
};

const FLAG_HELP: Flag = Flag{
    .flag_short = "-h",
    .flag_long = "--help",
    .desc = "Show this help message",
    .name = "help",
};

const FLAG_VERSION: Flag = Flag{
    .flag_short = "-v",
    .flag_long = "--version",
    .desc = "Show project's version",
    .name = "version",
};

const FLAG_DEBUG: Flag = Flag{
    .flag_short = "-d",
    .flag_long = "",
    .desc = "Enable debug mode",
    .name = "debug",
};

const FLAG_HELP_CONTROLS: Flag = Flag{
    .flag_short = "-hc",
    .desc = "Show the controls map",
    .name = "controls map",
};

const FLAG_SEED: Flag = Flag{
    .flag_short = "-s",
    .type = "<number>",
    .desc = "Random seed",
    .name = "seed",
};

const FLAG_MILLISECONDS: Flag = Flag{
    .flag_short = "-ms",
    .type = "<number>",
    .desc = "Frame delay in ms",
    .name = "milliseconds",
};

const FLAG_INTENSITY: Flag = Flag{
    .flag_short = "-i",
    .type = "<number>",
    .desc = "Intensity",
    .name = "intensity",
};

const FLAG_THEME_COLOR: Flag = Flag{
    .flag_short = "-tc",
    .type = "<enum>",
    .desc = "Theme color",
    .name = "theme color",
    .aux_desc = "(use \"help\" to list available modes)",
};

const FLAG_THEME_SYMBOL: Flag = Flag{
    .flag_short = "-ts",
    .type = "<enum>",
    .desc = "Theme symbol",
    .name = "Theme symbol",
    .aux_desc = "(use \"help\" to list available modes)",
};

const FLAG_COLOR_MODE: Flag = Flag{
    .flag_short = "-cm",
    .type = "<enum>",
    .desc = "Color mode",
    .name = "color mode",
    .aux_desc = "(use \"help\" to list available modes)",
};

pub const Configuration = struct {
    debug: bool = false,
    controls: bool = false,

    seed: u64 = 0,

    start_ms: i64 = 0,

    milliseconds: u64 = 50,

    intensity_per: f32 = 0.60,
    intensity: usize = 0,

    theme_symbol: symbol.Theme = symbol.Theme.Classic,
    theme_color: color.Theme = color.Theme.Warm,

    color_mode: formatter.FormatterCode = formatter.FormatterCode.RGB,

    formatter_matrix: formatter.FormatterMatrixUnion = formatter.FormatterMatrixUnion{ .unfo = .{} },
    formatter_cell: formatter.FormatterCellUnion = formatter.FormatterCellUnion{ .unfo = .{} },

    pub fn init(allocator: std.mem.Allocator, printer: *Printer, args: [][:0]u8) !@This() {
        defer printer.reset();

        var config = Configuration{};

        var i: usize = 1;
        while (i < args.len) : (i += 1) {
            const arg = args[i];

            if (std.mem.eql(u8, arg, FLAG_HELP.flag_short) or std.mem.eql(u8, arg, FLAG_HELP.flag_long.?)) {
                try print_help(allocator, printer, config);
                std.process.exit(0);
            }

            if (std.mem.eql(u8, arg, FLAG_VERSION.flag_short) or std.mem.eql(u8, arg, FLAG_VERSION.flag_long.?)) {
                try printer.printf("{any}: {s}\n", .{ build.name, build.version });
                std.process.exit(0);
            }

            if (std.mem.eql(u8, arg, FLAG_DEBUG.flag_short)) {
                config.debug = true;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_HELP_CONTROLS.flag_short)) {
                config.controls = true;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_SEED.flag_short)) {
                config.seed = try config.parseInt(u64, printer, args, i, FLAG_SEED, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_MILLISECONDS.flag_short)) {
                config.milliseconds = try config.parseInt(u64, printer, args, i, FLAG_MILLISECONDS, null, 1000 * 3);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_INTENSITY.flag_short)) {
                config.intensity = try config.parseInt(usize, printer, args, i, FLAG_INTENSITY, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_THEME_COLOR.flag_short)) {
                config.theme_color = try config.parseEnum(color.Theme, printer, args, i, FLAG_THEME_COLOR);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_THEME_SYMBOL.flag_short)) {
                config.theme_symbol = try config.parseEnum(symbol.Theme, printer, args, i, FLAG_THEME_SYMBOL);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_COLOR_MODE.flag_short)) {
                config.color_mode = try config.parseEnum(formatter.FormatterCode, printer, args, i, FLAG_COLOR_MODE);
                i += 1;
                continue;
            }

            try printer.printf("Unknown argument: {s}\n", .{arg});
            std.process.exit(1);
        }

        const timestamp = std.time.milliTimestamp();

        config.start_ms = timestamp;

        if (config.seed == 0) {
            config.seed = @intCast(timestamp);
        }

        init_formatters(&config);

        return config;
    }

    pub fn print_help(allocator: std.mem.Allocator, printer: *Printer, config: Configuration) !void {
        const message = try format_flags(allocator, printer, config);
        defer allocator.free(message);
        try printer.print(message);
    }

    pub fn format_flags(allocator: std.mem.Allocator, printer: *Printer, config: Configuration) ![]u8 {
        var buffer = try std.ArrayList(u8).initCapacity(allocator, 0);

        const intensity_default = try printer.format(
            "{d:.2} x matrix height",
            .{config.intensity_per},
        );

        try buffer.appendSlice(allocator, "\nUsage: zig-doom-fire          [options] \n\n");

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_HELP,
            .none,
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_VERSION,
            .none,
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_DEBUG,
            .{ .bool = config.debug },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_HELP_CONTROLS,
            .{ .bool = config.controls },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_SEED,
            .{ .str = "current time in ms" },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_MILLISECONDS,
            .{ .int = @intCast(config.milliseconds) },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_INTENSITY,
            .{ .str = intensity_default },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_THEME_COLOR,
            .{ .str = @tagName(config.theme_color) },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_THEME_SYMBOL,
            .{ .str = @tagName(config.theme_symbol) },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_COLOR_MODE,
            .{ .str = @tagName(config.color_mode) },
        ));

        return buffer.items;
    }

    pub fn format_flag(printer: *Printer, flag: Flag, default: TypeFormatter) ![]u8 {
        const flag_short = flag.flag_short;
        const flag_desc = flag.desc;

        var flag_long: []const u8 = "";
        if (flag.flag_long != null) {
            flag_long = flag.flag_long.?;
        }

        var flag_type: []const u8 = "";
        if (flag.type != null) {
            flag_type = flag.type.?;
        }

        var data = try printer.format("  {s:<3} {s:<12}  {s:<8}  {s}", .{ flag_short, flag_long, flag_type, flag_desc });

        if (default != .none) {
            const d = try default.format(printer);
            data = try printer.format("{s} (default: {s})", .{ data, d });
        }

        if (flag.aux_desc != null) {
            data = try printer.format("{s}\n{s:<32}{s}", .{ data, "", flag.aux_desc.? });
        }

        return try printer.format("{s} \n", .{data});
    }

    fn init_formatters(config: *Configuration) void {
        switch (config.color_mode) {
            formatter.FormatterCode.ANSI => {
                config.formatter_cell = formatter.FormatterCellUnion{ .ansi = .{} };
            },
            formatter.FormatterCode.RGB => {
                config.formatter_cell = formatter.FormatterCellUnion{ .rgb = .{} };
            },
        }

        config.formatter_matrix = formatter.FormatterMatrixUnion{ .unfo = .{} };

        return;
    }

    fn parseFloat(_: *@This(), comptime T: type, printer: *Printer, args: [][:0]u8, i: usize, flag: Flag, min: ?T, max: ?T) !T {
        if (i + 1 >= args.len) {
            try printer.printf("Missing argument for {s} ({s})\n", .{ flag.flag_short, flag.name });
            std.process.exit(1);
        }

        const value = args[i + 1];
        var result = std.fmt.parseFloat(T, value) catch {
            try printer.printf("Invalid {s} value: {s}\n", .{ flag.name, value });
            std.process.exit(1);
        };

        if (min != null) {
            result = @max(result, min.?);
        }

        if (max != null) {
            result = @min(result, max.?);
        }

        return result;
    }

    fn parseInt(_: *@This(), comptime T: type, printer: *Printer, args: [][:0]u8, i: usize, flag: Flag, min: ?T, max: ?T) !T {
        if (i + 1 >= args.len) {
            try printer.printf("Missing argument for {s} ({s})\n", .{ flag.flag_short, flag.name });
            std.process.exit(1);
        }

        const value = args[i + 1];
        var result = std.fmt.parseInt(T, value, 10) catch {
            try printer.printf("Invalid {s} value: {s}\n", .{ flag.name, value });
            std.process.exit(1);
        };

        if (min != null) {
            result = @max(result, min.?);
        }

        if (max != null) {
            result = @min(result, max.?);
        }

        return result;
    }

    fn parseEnum(self: *@This(), comptime T: type, printer: *Printer, args: [][:0]u8, i: usize, flag: Flag) !T {
        if (i + 1 >= args.len) {
            try printer.printf("Missing argument for {s} ({s})\n", .{ flag.flag_short, flag.name });
            std.process.exit(1);
        }

        const value = args[i + 1];
        if (std.mem.eql(u8, value, "help")) {
            try self.printEnumOptionsWithTitle(T, flag.name, printer);
            std.process.exit(0);
        }

        return std.meta.stringToEnum(T, value) orelse {
            try printer.printf("Invalid {s}: {s}\n", .{ flag.name, value });
            try self.printEnumOptions(T, printer);
            std.process.exit(1);
        };
    }

    fn printEnumOptions(self: *@This(), comptime T: type, printer: *Printer) !void {
        try self.printEnumOptionsWithTitle(T, "Available", printer);
    }

    fn printEnumOptionsWithTitle(_: *@This(), comptime T: type, title: []const u8, printer: *Printer) !void {
        const info = @typeInfo(T);
        try printer.printf("{s} options:\n", .{title});
        inline for (info.@"enum".fields) |field| {
            try printer.printf(" - {s}\n", .{field.name});
        }
    }
};

pub fn fromArgs(allocator: std.mem.Allocator, printer: *Printer) !Configuration {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    return Configuration.init(allocator, printer, args);
}
