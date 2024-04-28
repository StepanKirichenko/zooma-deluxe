const std = @import("std");
const rl = @import("rl.zig");
const paths = @import("paths.zig");

const math = std.math;

const Ball = struct {
    offset: f32,
    color: rl.Color,
};

const Vec = rl.Vector2;

const BG_COLOR = rl.Color.fromInt(0x181818ff);

const BALL_SPEED: f32 = 200;
const BALL_RADIUS: f32 = 30;

fn renderBall(ball: Ball, position: Vec) void {
    rl.drawCircleV(position, BALL_RADIUS, ball.color);
}

fn visualizePath(path: paths.Path, step: f32, color: rl.Color) void {
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
        Ball{ .offset = 400, .color = rl.Color.fromInt(0xb8ac32ff) },
        Ball{ .offset = 460, .color = rl.Color.fromInt(0xa83832ff) },
        Ball{ .offset = 700, .color = rl.Color.fromInt(0x3242a8ff) },
        Ball{ .offset = 800, .color = rl.Color.fromInt(0x32a852ff) },
        Ball{ .offset = 860, .color = rl.Color.fromInt(0xb8ac32ff) },
        Ball{ .offset = 1200, .color = rl.Color.fromInt(0xa83832ff) },
        Ball{ .offset = 1380, .color = rl.Color.fromInt(0x3242a8ff) },
    };

    const segments = [_]paths.Path{
        paths.LinePath.new(Vec.new(50, 50), Vec.new(500, 50)),
        paths.ArcPath.new(Vec.new(500, 50), Vec.new(500, 200), 0, .Clockwise),
        paths.LinePath.new(Vec.new(500, 200), Vec.new(300, 150)),
        paths.ArcPath.new(Vec.new(300, 150), Vec.new(150, 300), -100, .Counterclockwise),
        paths.ArcPath.new(Vec.new(150, 300), Vec.new(200, 500), 300, .Clockwise),
        paths.ArcPath.new(Vec.new(200, 500), Vec.new(300, 500), 0, .Counterclockwise),
        paths.ArcPath.new(Vec.new(300, 500), Vec.new(380, 420), 0, .Clockwise),
        paths.LinePath.new(Vec.new(380, 420), Vec.new(800, 420)),
    };

    const path = paths.MultiSegmentPath.new(&segments);

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

        for (balls) |ball| {
            const position = path.getPosition(ball.offset);
            renderBall(ball, position);
        }
    }
}
