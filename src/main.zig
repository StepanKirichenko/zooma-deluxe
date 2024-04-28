const std = @import("std");
const rl = @import("rl.zig");
const math = std.math;

const Ball = struct {
    offset: f32,
    color: rl.Color,
};

const Vec = rl.Vector2;

const BG_COLOR = rl.Color.fromInt(0x181818ff);

const BALL_SPEED: f32 = 100;
const BALL_RADIUS: f32 = 30;

const Path = union(enum) {
    line: LinePath,
    arc: ArcPath,

    pub fn getPosition(self: Path, offset: f32) Vec {
        return switch (self) {
            Path.line => |line| line.getPosition(offset),
            Path.arc => |arc| arc.getPosition(offset),
        };
    }

    pub fn getLength(self: Path) f32 {
        return switch (self) {
            Path.line => |line| line.length,
            Path.arc => |arc| arc.length,
        };
    }
};

const LinePath = struct {
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
        const length = start.distanceTo(end);
        const direction = end.subtract(start);
        return Path{ .line = LinePath{
            .start = start,
            .end = end,
            .length = length,
            .direction = direction,
        } };
    }
};

const ArcPath = struct {
    pub const Direction = enum { Clockwise, Counterclockwise };

    direction: Direction,
    center: Vec,
    start_displacement: Vec,
    angle: f32,
    length: f32,

    pub fn new(start: Vec, end: Vec, center_offset: f32, direction: Direction) Path {
        const chord_center = start.add(end.subtract(start).scale(0.5));
        const normal = chord_center.rotate(@as(f32, math.pi) / 2).normalize();
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

fn getCurvePosition(position: f32) Vec {
    const turns: f32 = 10 - (position / 360);
    const radians: f32 = turns * math.tau;
    const x = math.cos(radians) * turns * 30 + 400;
    const y = math.sin(radians) * turns * 30 + 300;
    return Vec{ .x = x, .y = y };
}

fn renderBall(ball: Ball, position: Vec) void {
    rl.drawCircleV(position, BALL_RADIUS, ball.color);
}

fn visualizePath(path: Path, step: f32, color: rl.Color) void {
    var offset: f32 = 0;
    const path_length = path.getLength();
    while (offset < path_length) : (offset += step) {
        rl.drawCircleV(path.getPosition(offset), 3, color);
    }
}

pub fn main() void {
    rl.initWindow(800, 600, "Raylib window");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var balls = [_]Ball{
        Ball{ .offset = 0, .color = rl.Color.fromInt(0x32a852ff) },
        Ball{ .offset = 150, .color = rl.Color.fromInt(0xb8ac32ff) },
        Ball{ .offset = 300, .color = rl.Color.fromInt(0xa83832ff) },
        Ball{ .offset = 360, .color = rl.Color.fromInt(0x3242a8ff) },
    };

    const start = Vec.new(400, 200);
    const end = Vec.new(600, 300);
    const path = ArcPath.new(end, start, 200, .Clockwise);

    while (!rl.windowShouldClose()) {
        // Frame update
        const delta = rl.getFrameTime();

        balls[0].offset += BALL_SPEED * delta;
        for (1..balls.len) |i| {
            if (balls[i].offset - balls[i - 1].offset > BALL_RADIUS * 2) break;
            balls[i].offset = balls[i - 1].offset + BALL_RADIUS * 2;
        }

        // Rendering
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(BG_COLOR);

        visualizePath(path, 20, rl.Color.red);
        rl.drawCircleV(path.arc.center, 10, rl.Color.blue);
        rl.drawCircleV(start, 10, rl.Color.green);
        rl.drawCircleV(end, 10, rl.Color.purple);
        rl.drawCircleV(start.add(end.subtract(start).scale(0.5)), 5, rl.Color.blue);

        for (balls) |ball| {
            const position = path.getPosition(ball.offset);
            renderBall(ball, position);
        }
    }
}
