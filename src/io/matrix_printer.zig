const std = @import("std");

const Printer = @import("printer.zig").Printer;

const Vector = @import("../domain/matrix.zig").LinearMatrix;

const symbol = @import("../domain/symbol.zig");
const color = @import("../domain/color.zig");

const formatter = @import("formatter.zig");

pub const LinearMatrixPrinter = struct {
    allocator: *std.mem.Allocator,

    printer: *Printer,
    formatter: formatter.FormatterCellUnion,

    prefix: []const u8,
    sufix: []const u8,

    color_manager: color.ColorManager,
    mode_meta: symbol.ThemeMeta,

    pub fn init(
        allocator: *std.mem.Allocator,
        printer: *Printer,
        color_manager: color.ColorManager,
        fmt_mtrx: formatter.FormatterMatrixUnion,
        fmt_cell: formatter.FormatterCellUnion,
        mode_code: symbol.Theme,
    ) !@This() {
        return .{
            .allocator = allocator,
            .printer = printer,
            .formatter = fmt_cell,
            .prefix = fmt_mtrx.prefix(),
            .sufix = fmt_mtrx.sufix(),
            .color_manager = color_manager,
            .mode_meta = symbol.metaOf(mode_code),
        };
    }

    pub fn print(self: *@This(), vctr: *Vector) !void {
        if (vctr.vector() == null or vctr.vector().?.len == 0) {
            return;
        }

        const matrix = vctr.vector().?;
        const rows = vctr.rows_len();
        const columns = vctr.cols_len();

        const char_fmt_len = self.formatter.fmt_bytes() + self.mode_meta.total_bytes;
        const mtrx_fmt_len = rows * columns * char_fmt_len;
        const estimated_size = self.prefix.len + mtrx_fmt_len + self.sufix.len;

        var buffer = try std.ArrayList(u8).initCapacity(self.allocator.*, estimated_size);
        defer buffer.deinit(self.allocator.*);

        const buf = try self.allocator.alloc(u8, char_fmt_len);
        defer self.allocator.free(buf);

        try buffer.appendSlice(self.allocator.*, self.prefix);

        for (0..rows) |y| {
            for (0..columns) |x| {
                const rgb = self.color_manager.find(matrix[y * columns + x]);

                var cell: []const u8 = self.mode_meta.inactive_char;
                if (rgb) |c| {
                    cell = try self.formatter.format(buf, c[0], c[1], c[2], self.mode_meta.active_char);
                }

                try buffer.appendSlice(self.allocator.*, cell);
            }

            if (y < rows - 1) {
                try buffer.append(self.allocator.*, '\n');
            }
        }

        try buffer.appendSlice(self.allocator.*, self.sufix);

        try self.printer.print(buffer.items);
    }

    pub fn reset(self: *@This()) void {
        self.allocator.free(self.prefix);
    }
};
