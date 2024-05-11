#-------------------------------------------------------------------------------
# Arceus Plate Transform Animation
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::ArceusTransform < Battle::Scene::Animation
  PLATE_BURST_VARIANCES = {
    :NORMAL   => [Tone.new(0, 0, 0),          Tone.new(0, 0, -192),       Tone.new(0, 0, -96),        Tone.new(0, -128, -248)], 
    :FIGHTING => [Tone.new(-12, -116, -192),  Tone.new(-12, -116, -192),  Tone.new(-10, -50, -96),    Tone.new(-30, -128, -248)],
    :FLYING   => [Tone.new(0, 0, 0),          Tone.new(-30, -22, 0),      Tone.new(-10, -10, 0),      Tone.new(-70, -70, 0)],
    :POISON   => [Tone.new(-60, -200, 0),     Tone.new(-30, -100, 0),     Tone.new(-20, -30, 0),      Tone.new(-60, -200, 0)],
    :GROUND   => [Tone.new(-10, -13, -36),    Tone.new(-10, -30, -70),    Tone.new(-10, -13, -36),    Tone.new(-15, -55, -120)],
    :ROCK     => [Tone.new(-25, -55, -120),   Tone.new(-20, -30, -70),    Tone.new(-20, -13, -36),    Tone.new(-25, -55, -120)],
    :BUG      => [Tone.new(-45, -26, -58),    Tone.new(-30, -8, -65),     Tone.new(-16, -8, -29),     Tone.new(-45, -26, -58)],
    :GHOST    => [Tone.new(-60, -200, 0),     Tone.new(-30, -100, 0),     Tone.new(-20, -30, 0),      Tone.new(-60, -200, 0)],
    :STEEL    => [Tone.new(0, 0, 0),          Tone.new(-40, -40, -40),    Tone.new(-10, -10, -10),    Tone.new(-128, -128, -128)], 
    :QMARKS   => [Tone.new(-60, -200, 0),     Tone.new(-30, -8, -65),     Tone.new(-16, -8, -29),     Tone.new(-45, -26, -58)],
    :FIRE     => [Tone.new(0, -128, -248),    Tone.new(0, -29, -80),      Tone.new(0, -30, -96),      Tone.new(0, -128, -248)],
    :WATER    => [Tone.new(-192, -96, 0),     Tone.new(-128, -64, 0),     Tone.new(-96, -48, 0),      Tone.new(-192, -96, 0)],
    :GRASS    => [Tone.new(-160, 0, -160),    Tone.new(-128, 0, -128),    Tone.new(-80, 0, -80),      Tone.new(-160, 0, -160)],
    :ELECTRIC => [Tone.new(0, 0, -192),       Tone.new(0, 0, -192),       Tone.new(0, -64, -144),     Tone.new(0, -128, -248)],
    :PSYCHIC  => [Tone.new(-6, -35, 0),       Tone.new(-6, -35, 0),       Tone.new(0, -20, 0),        Tone.new(-14, -100, 0)],
    :ICE      => [Tone.new(0, 0, 0),          Tone.new(-184, -40, 0),     Tone.new(-184, -40, 0),     Tone.new(-192, -128, -32)],
    :DRAGON   => [Tone.new(-26, -29, -24),    Tone.new(-30, -22, 0),      Tone.new(-26, -29, -24),    Tone.new(-50, -70, -40)],
    :DARK     => [Tone.new(-248, -248, -248), Tone.new(-248, -248, -248), Tone.new(-248, -248, -248), Tone.new(-248, -248, -248)],
    :FAIRY    => [Tone.new(0, -55, -32),      Tone.new(0, -25, 0),        Tone.new(0, -10, 0),        Tone.new(0, -55, -32)],
  }

  def initialize(sprites, viewport, index, type)
    @index = index
    @type  = type
    super(sprites, viewport)
  end

  def createProcesses
    batSprite = @sprites["pokemon_#{@index}"]
    ballPos = Battle::Scene.pbBattlerPosition(@index, batSprite.sideSize)
    delay = 0
    battlerX = batSprite.x
    battlerY = batSprite.y-100
    num_particles = 15
    num_rays = 10
    glare_fade_duration = 8   # Lifetimes/durations are in 20ths of a second
    particle_lifetime = 15
    particle_fade_duration = 8
    ray_lifetime = 13
    ray_fade_duration = 5
    ray_min_radius = 24   # How far out from the center a ray starts
    variances = PLATE_BURST_VARIANCES[@type] || PLATE_BURST_VARIANCES[:NORMAL]
    # Set up Plate
    plate = addNewSprite(battlerX, battlerY+40, "Graphics/Battle animations/Arceus_Plate", PictureOrigin::CENTER)
    plate.setZ(0, 105)
    plate.setZoom(0, 100)
    plate.setTone(0, variances[3])
    plate.setVisible(0, false)
    plate.setOpacity(0, 0)
    plate.setVisible(delay, true)
    plate.moveOpacity(delay, 10, 255)
    plate.moveXY(delay, 10, battlerX, battlerY)
    delay = delay + 10
    plate.moveTone(delay, glare_fade_duration / 2, variances[1])
    plate.moveOpacity(delay + glare_fade_duration + 3, glare_fade_duration, 0)
    plate.setVisible(delay + 19, false) 
    # Set up Battler
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    battler.setXY(0, battlerX, batSprite.y)
    battler.setZoom(0, 100)
    col = variances[3]
    col.red += 255
    col.green += 255
    col.blue += 255
    battler.setTone(delay + 6, col)
    battler.moveTone(delay + glare_fade_duration + 3, glare_fade_duration, Tone.new(0,0,0,0))
    # Set up glare particles
    glare1 = addNewSprite(battlerX, battlerY, "Graphics/Battle animations/ballBurst_particle", PictureOrigin::CENTER)
    glare2 = addNewSprite(battlerX, battlerY, "Graphics/Battle animations/ballBurst_particle", PictureOrigin::CENTER)
    [glare1, glare2].each_with_index do |particle, num|
      particle.setZ(0, 105 + num)
      particle.setZoom(0, 0)
      particle.setTone(0, variances[2 - (2 * num)])
      particle.setVisible(0, false)
    end
    [glare1, glare2].each_with_index do |particle, num|
      particle.moveTone(delay + glare_fade_duration + 3, glare_fade_duration / 2, variances[1 - num])
    end
    # Animate glare particles
    [glare1, glare2].each { |p| p.setVisible(delay, true) }
    glare1.moveZoom(delay, glare_fade_duration, 250)
    glare1.moveOpacity(delay + glare_fade_duration + 3, glare_fade_duration, 0)
    glare2.moveZoom(delay, glare_fade_duration, 150)
    glare2.moveOpacity(delay + glare_fade_duration + 3, glare_fade_duration - 2, 0)
    [glare1, glare2].each { |p| p.setVisible(delay + 19, false) }
    # Rays
    num_rays.times do |i|
      # Set up ray
      angle = rand(360)
      radian = (angle + 90) * Math::PI / 180
      start_zoom = rand(50...100)
      ray = addNewSprite(battlerX + ray_min_radius * Math.cos(radian),
                         battlerY - ray_min_radius * Math.sin(radian),
                         "Graphics/Battle animations/ballBurst_ray", PictureOrigin::BOTTOM)
      ray.setZ(0, 100)
      ray.setZoomXY(0, 200, start_zoom)
      ray.setTone(0, variances[0])
      ray.setOpacity(0, 0)
      ray.setVisible(0, false)
      ray.setAngle(0, angle)
      # Animate ray
      start = delay + i / 2
      ray.setVisible(start, true)
      ray.moveZoomXY(start, ray_lifetime, 200, start_zoom * 6)
      ray.moveOpacity(start, 2, 255)   # Quickly fade in
      ray.moveOpacity(start + ray_lifetime - ray_fade_duration, ray_fade_duration, 0)   # Fade out
      ray.moveTone(start + ray_lifetime - ray_fade_duration, ray_fade_duration, variances[1])
      ray.setVisible(start + ray_lifetime, false)
    end
    # Particles
    num_particles.times do |i|
      # Set up particles
      particle1 = addNewSprite(battlerX, battlerY, "Graphics/Battle animations/ballBurst_particle", PictureOrigin::CENTER)
      particle2 = addNewSprite(battlerX, battlerY, "Graphics/Battle animations/ballBurst_particle", PictureOrigin::CENTER)
      [particle1, particle2].each_with_index do |particle, num|
        particle.setZ(0, 110 + num)
        particle.setZoom(0, (80 - (num * 20)))
        particle.setTone(0, variances[2 - (2 * num)])
        particle.setVisible(0, false)
      end
      # Animate particles
      start = delay + i / 4
      max_radius = rand(256...384)
      angle = rand(360)
      radian = angle * Math::PI / 180
      [particle1, particle2].each_with_index do |particle, num|
        particle.setVisible(start, true)
        particle.moveDelta(start, particle_lifetime, max_radius * Math.cos(radian), max_radius * Math.sin(radian))
        particle.moveZoom(start, particle_lifetime, 10)
        particle.moveTone(start + particle_lifetime - particle_fade_duration,
                           particle_fade_duration / 2, variances[3 - (3 * num)])
        particle.moveOpacity(start + particle_lifetime - particle_fade_duration,
                             particle_fade_duration,
                             0)   # Fade out at end
        particle.setVisible(start + particle_lifetime, false)
      end
    end
  end
end
