const std = @import("std");

const kit_formatter = @import("terminal_kit").formatter;

/// Supported output formats for rendering matrix cells.
pub const FormatterCode = enum {
    /// ANSI terminal color escape sequences.
    ansi,
    /// RGB color values.
    rgb,
};

/// Returns the matrix formatter associated with a formatter code.
///
/// The matrix formatter is currently the same for all supported formats.
pub fn matrix_union_of(_: FormatterCode) kit_formatter.FormatterMatrixUnion {
    return .{ .unfo = .{} };
}

/// Returns the cell formatter associated with a formatter code.
pub fn cell_union_of(f: FormatterCode) kit_formatter.FormatterCellUnion {
    return switch (f) {
        FormatterCode.ansi => .{ .ansi = .{} },
        FormatterCode.rgb => .{ .rgb = .{} },
    };
}
