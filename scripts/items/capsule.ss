// -----------------------------------------------------------------------------
// File: bumpers.ss
// Description: bumper script
// Author: Alexandre Martins <http://opensurge2d.org>
// License: MIT
// -----------------------------------------------------------------------------
using SurgeEngine.Actor;
using SurgeEngine.Brick;
using SurgeEngine.Level;
using SurgeEngine.Vector2;
using SurgeEngine.Transform;
using SurgeEngine.Audio.Sound;
using SurgeEngine.Collisions.CollisionBox;

object "Goal Capsule" is "entity", "basic"
{
    actor = Actor("Goal Capsule");
    brick = [ Brick("Goal Capsule Mask 1"), Brick("Goal Capsule Mask 2") ];
    collider = CollisionBox(32, 16).setAnchor(0.5, 5);
    sfx = Sound("samples/switch.wav");
    transform = Transform();
    explosionCounter = 0;
    animalCounter = 0;
    player = null; // the winner

    state "main"
    {
    }

    state "exploding"
    {
        if(timeout(0.10)) {
            if(++explosionCounter <= 15)
                state = "explode";
            else
                state = "opening";
        }
    }

    state "explode"
    {
        // compute the explosion offset
        width = Math.max(0, actor.width - 16);
        height = Math.max(0, actor.height - 32);
        lenx = Math.floor(width / 8);
        leny = Math.floor(height / 4);
        gridx = Math.floor(Math.random() * (1 + lenx)) - lenx / 2;
        gridy = Math.floor(Math.random() * (1 + leny));

        // create explosion
        spawnExplosion(gridx, gridy);

        // done with this explosion
        state = "exploding";
    }

    state "opening"
    {
        // spawn many animals
        for(s = 1, i = 0; i <= 7; i++) {
            x = Math.floor(i / 2) * (s = -s);
            spawnAnimal(x, 0.16 + i * 0.12);
        }
        for(i = 1; i <= 9; i++) {
            x = Math.floor(Math.random() * 5) - 2;
            spawnAnimal(x, 1.0 + i * 0.12);
        }

        // spawn capsule parts
        spawnBrokenParts();

        // open the capsule
        actor.anim = 2;
        state = "open";
    }

    state "open"
    {
        // the capsule is open!
        if(timeout(1.0)) {
            Level.clear();
            state = "done";
        }
    }

    state "done"
    {
        // we're done!
    }

    // detect when the player opens the capsule
    fun onOverlap(otherCollider)
    {
        if(otherCollider.entity.hasTag("player")) {
            player = otherCollider.entity;
            if(!player.midair) {
                collider.enabled = false;
                explodeCapsule();
            }
        }
    }

    fun explodeCapsule()
    {
        if(state == "main") {
            brick[0].enabled = false;
            brick[1].enabled = true;
            actor.anim = 1;
            sfx.play();
            state = "exploding";
        }
    }

    fun spawnExplosion(gridx, gridy)
    {
        Level.spawnEntity("Explosion",
            transform.position.translatedBy(
                8 * gridx,
                4 * -(gridy + 2)
            )
        );
    }

    fun spawnAnimal(gridx, secondsBeforeMoving)
    {
        animal = Level.spawnEntity("Animal",
            transform.position.translatedBy(
                8 * gridx,
                -12
            )
        );
        animal.secondsBeforeMoving = secondsBeforeMoving;
        animal.zindex += 0.1 - 0.001 * (++animalCounter);
    }

    fun spawnBrokenParts()
    {
        Level.spawnEntity("Goal Capsule Broken Part",
            transform.position.translatedBy(-16, -32)
        ).goLeft();

        Level.spawnEntity("Goal Capsule Broken Part",
            transform.position.translatedBy(0, -32)
        ).goUp();

        Level.spawnEntity("Goal Capsule Broken Part",
            transform.position.translatedBy(16, -32)
        ).goRight();
    }

    fun constructor()
    {
        //collider.visible = true;
        brick[0].enabled = true;
        brick[1].enabled = false;
    }
}

object "Goal Capsule Broken Part" is "entity", "private", "disposable"
{
    public velocity = Vector2(90, 180); // initial velocity in px/s
    public angularSpeed = 720; // degrees per second

    xsp = 0;
    ysp = 0;
    phi = 0;
    grv = 828;
    part = "core"; // left | right | core
    actor = [
        Actor("Goal Capsule Broken Core"),
        Actor("Goal Capsule Broken Lateral")
    ];
    transform = Transform();
    r = Math.random() * 0.5;
    t = 1.0;

    state "main"
    {
        // setup
        actor[0].visible = actor[1].visible = false;
        actor[0].zindex = actor[1].zindex = 0.6;
        sign = 0;

        // check broken part type
        if(part == "core") {
            actor[0].visible = true;
        }
        else if(part == "left") {
            sign = -1;
            actor[1].visible = true;
            actor[1].anim = 0;
        }
        else if(part == "right") {
            sign = 1;
            actor[1].visible = true;
            actor[1].anim = 1;
        }

        // initializing velocities
        phi = -sign * Math.abs(angularSpeed);
        xsp = sign * Math.abs(velocity.x);
        ysp = -Math.abs(velocity.y);

        // moving
        state = "moving";
    }

    state "moving"
    {
        // move
        dt = Time.delta;
        ysp += grv * dt;
        transform.move(xsp * dt, ysp * dt);
        transform.rotate(phi * dt);

        // neat explosion ;)
        if((t += Time.delta) >= 0.2 * (1 + r)) {
            t = 0;
            state = "explode";
        }
    }

    state "explode"
    {
        explosion = Level.spawnEntity("Explosion", transform.position).mute();
        explosion.zindex = actor[0].zindex + 0.01;
        state = "moving";
    }

    fun goLeft()
    {
        part = "left";
        return this;
    }

    fun goRight()
    {
        part = "right";
        return this;
    }

    fun goUp()
    {
        part = "core";
        return this;
    }
}