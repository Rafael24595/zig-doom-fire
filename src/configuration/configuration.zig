const std = @import("std");

const build = @import("build.zig.zon");

const terminal_kit = @import("terminal_kit");

const Printer = terminal_kit.printer.Printer;

const Flag = terminal_kit.configuration.Flag;
const kit_conf = terminal_kit.configuration;

const kit_color = terminal_kit.color;

const matrix = @import("../domain/matrix.zig");
const symbol = @import("../domain/symbol.zig");
const color = @import("../domain/color.zig");

const formatter = @import("../io/formatter.zig");

const frame_pause_ms: u64 = switch (builtin.os.tag) {
    .windows => 45,
    else => 50,
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

    milliseconds: u64 = frame_pause_ms,

    intensity_per: f32 = 0.60,
    intensity: usize = 0,

    theme_symbol: symbol.Theme = .classic,
    theme_color: color.Theme = .warm,

    color_mode: formatter.FormatterCode = .rgb,

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
                config.seed = try kit_conf.parse_int(u64, printer, args, i, FLAG_SEED, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_MILLISECONDS.flag_short)) {
                config.milliseconds = try kit_conf.parse_int(u64, printer, args, i, FLAG_MILLISECONDS, null, 1000 * 3);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_INTENSITY.flag_short)) {
                config.intensity = try kit_conf.parse_int(usize, printer, args, i, FLAG_INTENSITY, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_THEME_COLOR.flag_short)) {
                config.theme_color = try kit_conf.parse_enum(color.Theme, printer, args, i, FLAG_THEME_COLOR);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_THEME_SYMBOL.flag_short)) {
                config.theme_symbol = try kit_conf.parse_enum(symbol.Theme, printer, args, i, FLAG_THEME_SYMBOL);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_COLOR_MODE.flag_short)) {
                config.color_mode = try kit_conf.parse_enum(formatter.FormatterCode, printer, args, i, FLAG_COLOR_MODE);
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

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_HELP,
            .none,
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_VERSION,
            .none,
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_DEBUG,
            .{ .bool = config.debug },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_HELP_CONTROLS,
            .{ .bool = config.controls },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_SEED,
            .{ .str = "current time in ms" },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_MILLISECONDS,
            .{ .int = @intCast(config.milliseconds) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_INTENSITY,
            .{ .str = intensity_default },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_THEME_COLOR,
            .{ .str = @tagName(config.theme_color) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_THEME_SYMBOL,
            .{ .str = @tagName(config.theme_symbol) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_COLOR_MODE,
            .{ .str = @tagName(config.color_mode) },
        ));

        return buffer.items;
    }
};

pub fn from_args(allocator: std.mem.Allocator, printer: *Printer) !Configuration {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    return Configuration.init(allocator, printer, args);
}
