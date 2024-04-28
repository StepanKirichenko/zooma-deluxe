const std = @import("std");
const rl = @import("rl.zig");
const math = std.math;

const Vec = rl.Vector2;

pub const Path = union(enum) {
    line: LinePath,
    arc: ArcPath,
    multiSegment: MultiSegmentPath,

    pub fn getPosition(self: Path, offset: f32) Vec {
        return switch (self) {
            Path.line => |line| line.getPosition(offset),
            Path.arc => |arc| arc.getPosition(offset),
            Path.multiSegment => |ms| ms.getPosition(offset),
        };
    }

    pub fn getLength(self: Path) f32 {
        return switch (self) {
            Path.line => |line| line.length,
            Path.arc => |arc| arc.length,
            Path.multiSegment => |ms| ms.length,
        };
    }
};

pub const LinePath = struct {
    start: Vec,
    end: Vec,
    length: f32,
    direction: Vec,

    pub fn getPosition(self: LinePath, offset: f32) Vec {
        const t = offset / self.length;
        const movement = self.direction.scale(t);
        const position = self.start.add(movement);
        return position;
    }

    pub fn new(start: Vec, end: Vec) Path {
        const length = start.distance(end);
        const direction = end.subtract(start);
        return Path{ .line = LinePath{
            .start = start,
            .end = end,
            .length = length,
            .direction = direction,
        } };
    }
};

pub const ArcPath = struct {
    pub const Direction = enum { Clockwise, Counterclockwise };

    direction: Direction,
    center: Vec,
    start_displacement: Vec,
    end_displacement: Vec,
    angle: f32,
    length: f32,

    pub fn new(start: Vec, end: Vec, center_offset: f32, direction: Direction) Path {
        const half_diff = end.subtract(start).scale(0.5);
        const chord_center = start.add(half_diff);
        const normal = half_diff.rotate(@as(f32, math.pi) / 2).normalize();
        const center = chord_center.add(normal.scale(center_offset));
        const start_displacement = start.subtract(center);
        const end_displacement = end.subtract(center);
        var vec_angle = Vec.angle(start_displacement, end_displacement);
        if (vec_angle < 0) {
            vec_angle += math.tau;
        }
        const arc_angle = if (direction == .Clockwise) vec_angle else math.tau - vec_angle;
        const radius = start_displacement.length();
        const length = arc_angle * radius;
        return Path{ .arc = ArcPath{
            .direction = direction,
            .center = center,
            .start_displacement = start_displacement,
            .end_displacement = end_displacement,
            .angle = arc_angle,
            .length = length,
        } };
    }

    pub fn getPosition(self: ArcPath, offset: f32) Vec {
        const t = offset / self.length;
        const direction_coeff: f32 = if (self.direction == .Clockwise) 1 else -1;
        const rotation = self.angle * t * direction_coeff;
        const displacement = self.start_displacement.rotate(rotation);
        const position = self.center.add(displacement);
        return position;
    }
};

pub const MultiSegmentPath = struct {
    segments: []const Path,
    length: f32,

    pub fn new(segments: []const Path) Path {
        if (segments.len == 0) {
            @panic("MultiSegmentPath should have at least one segment");
        }

        var length: f32 = 0;
        for (segments) |segment| {
            length += segment.getLength();
        }

        return Path{ .multiSegment = MultiSegmentPath{
            .segments = segments,
            .length = length,
        } };
    }

    pub fn getPosition(self: MultiSegmentPath, offset: f32) Vec {
        var i: usize = 0;
        var offset_left = offset;
        while (i < self.segments.len - 1 and offset_left > self.segments[i].getLength()) {
            offset_left -= self.segments[i].getLength();
            i += 1;
        }

        if (i >= self.segments.len) {
            i = self.segments.len - 1;
        }

        return self.segments[i].getPosition(offset_left);
    }

    pub fn getLength(self: MultiSegmentPath) f32 {
        return self.length;
    }
};
