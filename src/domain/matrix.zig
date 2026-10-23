const std = @import("std");

const MiniLCG = @import("terminal_kit").mini_lcg.MiniLCG;

const FIRE_SOURCE_ROW_OFFSET: usize = 2;

pub const BuildError = error{
    InvalidDimensions,
    MatrixTooLarge,
};

pub const LinearMatrix = struct {
    allocator: std.mem.Allocator,

    lcg: *MiniLCG,

    status: bool = false,

    intensity: usize = 0,

    cols: usize = 0,
    rows: usize = 0,

    matrix: ?[]usize = null,

    pub fn init(allocator: std.mem.Allocator, lcg: *MiniLCG) LinearMatrix {
        return LinearMatrix{
            .allocator = allocator,
            .lcg = lcg,
            .status = false,
            .intensity = 0,
            .matrix = null,
        };
    }

    pub fn free(self: *@This()) void {
        if (self.matrix != null) {
            self.allocator.free(self.matrix.?);
            self.matrix = null;
        }
    }

    pub fn build(
        self: *@This(),
        cols: usize,
        rows: usize,
        intensity: usize,
    ) !void {
        if (cols == 0 or rows < 2) {
            return BuildError.InvalidDimensions;
        }

        const len = std.math.mul(usize, cols, rows) catch {
            return BuildError.MatrixTooLarge;
        };

        const matrix = try self.allocator.alloc(usize, len);
        @memset(matrix, 0);

        if (self.matrix) |old_matrix| {
            self.allocator.free(old_matrix);
        }

        self.intensity = intensity;

        self.cols = cols;
        self.rows = rows;

        self.matrix = matrix;

        self.on_fire();
    }

    pub fn switch_fire(self: *@This()) void {
        if (self.status) {
            return self.off_fire();
        }
        return self.on_fire();
    }

    inline fn on_fire(self: *@This()) void {
        for (0..self.cols) |x| {
            const last_r = self.idx(self.rows - 1, x);
            self.matrix.?[last_r] = self.intensity;
        }
        self.status = true;
    }

    inline fn off_fire(self: *@This()) void {
        for (0..self.cols) |x| {
            const last_r = self.idx(self.rows - 1, x);
            self.matrix.?[last_r] = 0;
        }
        self.status = false;
    }

    pub fn intensity_len(self: @This()) usize {
        return self.intensity;
    }

    pub fn vector(self: @This()) ?[]usize {
        return self.matrix;
    }

    pub fn cols_len(self: @This()) usize {
        return self.cols;
    }

    pub fn rows_len(self: @This()) usize {
        return self.rows;
    }

    pub fn next(self: *@This(), wind: isize, oxygen: isize) !void {
        if (self.matrix == null) {
            return;
        }

        const last_row = self.rows - FIRE_SOURCE_ROW_OFFSET;
        const wind_fix = wind + 1;

        var matrix = self.matrix.?;

        for (0..self.rows - 1) |y| {
            const source_start = (y + 1) * self.cols;
            const target_start = y * self.cols;

            for (0..self.cols) |x| {
                const source = source_start + x;

                var decay = self.lcg.rand_in_range(0, 2);
                if (oxygen != 0) {
                    decay = self.apply_oxygen(decay, oxygen);
                }

                const rand_dst = self.lcg.rand_in_range(0, 2);

                const i_rand_dst: isize = @intCast(rand_dst);
                const i_x: isize = @intCast(x);

                const i_target = std.math.clamp(
                    i_x + (i_rand_dst - wind_fix),
                    0,
                    self.cols - 1,
                );

                var target: usize = @intCast(i_target);
                target = target_start + target;

                matrix[target] = matrix[source] -| decay;

                if (wind != 0 and y != last_row) {
                    matrix[source] = matrix[source] -| 1;
                }
            }
        }
    }

    inline fn apply_oxygen(self: *@This(), decay: usize, oxygen: isize) usize {
        const rand_oxigen = self.lcg.rand_in_range(0, 100);
        const accept = oxygen * 20;

        if (oxygen > 0 and rand_oxigen < accept) {
            return decay -| 1;
        }

        if (oxygen < 0 and rand_oxigen < -accept) {
            return decay + 1;
        }

        return decay;
    }

    inline fn idx(self: @This(), y: usize, x: usize) usize {
        return y * self.cols + x;
    }
};
