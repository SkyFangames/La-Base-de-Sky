######Egg Hatcher By: KYU  ##################################################
#There are two ways of using this script:
#   -Making an object:
#     First, add the following line to items PBS 
#     (change xxx to the id of the item):
#        XXX,EGGHATCHER,Egg Hatcher,Egg Hatchers,8,0,"An Egg Hatcher in which to keep up to 6 eggs until they hatch.",2,0,6
#     If you´re using v19, add EGGHATCHER.png to the Graphics/Items folder.
#     Else, add itemXXX.png to the Graphics/Icons folder.
#     
#     The functionality code is already implemented within this script. 
#     That includes item usage and egg storage after receiving them.
#
#   -External script call:
#     Whether calling it from the menu or a random npc, just call the following 
#     method:
#         openHatcher
#     In case of using this method to use the hatcher, you can use a 
#     global switch to make it available to the player. 
#     Just change openHatcher_SWITCH to the id of the switch you wanna use.
# 
#CREDITS MUST BE GIVEN TO EVERYONE LISTED ON THE POST
################################################################################

if defined?(PluginManager)
  PluginManager.register({
  :name => "Egg Hatcher",
  :essentials => "21.1",
  :version => "1.1",
  :credits => ["Kyu","Clara","Turner","DPertierra"]
  })
end

class PokemonGlobalMetadata
  attr_accessor :eggs
  alias old_initialize initialize
  def initialize
    old_initialize
    @eggs ||= [nil,nil,nil,nil,nil,nil]
  end
end

#Box sprite of the hatcher
class EggSprite < Sprite
  def initialize(viewport,selected,pokemon, x, y)
    super(viewport)
    @sprites = {}
    @animframe = 0
    @curFrame = 0
    @pokemon = pokemon
    @selected = selected
    self.bitmap = Bitmap.new(68, 100)
    self.x = x
    self.y = y
    refresh
  end
  
  def refresh
    if @pokemon != nil
      @frameskip = 20
      steps = @pokemon.steps_to_hatch
      sprite = GameData::Species.egg_icon_filename(@pokemon.species, @pokemon.form)
      @frameskip = 15 if steps<10200
      @frameskip = 10 if steps<2550
      @frameskip = 5 if steps<1275
      @sprites["egg"] = AnimatedSprite.create(sprite,2,@frameskip,self.viewport)
      @sprites["egg"].x = self.x + 2
      @sprites["egg"].y = self.y - 5
      @sprites["egg"].play
      base = Color.new(6,35,52)
      shadow= Color.new(169,179,184)
      pbSetSystemFont(self.bitmap)
      pbDrawTextPositions(self.bitmap,[[steps.to_s,35,
      defined?(Settings::EGG_LEVEL) ? 60 : 65,2,base,shadow]])
    end

    if @selected
      self.bitmap.blt(0,0,Bitmap.new("Graphics/Pictures/Egg Hatcher/selection"),Rect.new(0,0,68,100))
    end
  end

  def dispose
    super
    pbDisposeSpriteHash(@sprites)
  end
  
  def update
    pbUpdateSpriteHash(@sprites)
  end
end

#GlobalScene
class Hatcher
  def initialize
    if !$PokemonGlobal.eggs
      $PokemonGlobal.eggs ||= [nil,nil,nil,nil,nil,nil]
    end
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @eggs = {}
    @index = 0
    
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = Bitmap.new("Graphics/Pictures/Egg Hatcher/hatcherbg")

    @sprites["text"] = Sprite.new(@viewport)
    @sprites["text"].bitmap = Bitmap.new(183,183)
    @sprites["text"].x = 290 
    @sprites["text"].y = 80
    pbSetSystemFont(@sprites["text"].bitmap)
    refresh
  end
  
  def refresh
    disposeEggs
    @sprites["text"].bitmap.clear
    eggs = $PokemonGlobal.eggs
    for index in 0..5
      if index < 3
        x = 46 + 80*index
        y = 46
      else
        x = 46 + 80*(index - 3)
        y = 158
      end
      selected = (index == @index)? true : false
      @eggs["#{index}"] = EggSprite.new(@viewport,selected,eggs[index], x, y)
    end
    
    if eggs[@index] != nil
      pokemon = eggs[@index]
      steps = pokemon.steps_to_hatch
      eggstate = _INTL("Parece que va a tardar un buen rato en eclosionar.")
      eggstate = _INTL("¿Qué eclosionará de esto? No parece estar cerca de eclosionar.") if steps < 10_200
      eggstate = _INTL("Parece moverse ocasionalmente. Puede estar cerca de eclosionar.") if steps < 2550
      eggstate = _INTL("¡Se escuchan sonido desde dentro! ¡Eclosionará pronto!") if steps < 1275
      drawFormattedTextEx(@sprites["text"].bitmap,0,10,183,eggstate)
    else
      eggstate = _INTL("Selecciona una incubadora para añadir un Huevo.")
      drawFormattedTextEx(@sprites["text"].bitmap,0,10,183,eggstate)
    end
  end
  
  def disposeEggs
    @eggs.each_value{|egg|
      egg.dispose
    }
  end
  
  def dispose
    disposeEggs
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
  
  def update
    loop do
      @eggs.each_value{|egg|
      egg.update
      }
      #Egg selector
      if Input.trigger?(Input::RIGHT) && (@index+1)%3 != 0
        @index += 1
        pbSEPlay("Choose")
        refresh
      end
      if Input.trigger?(Input::LEFT) && (@index != 0 && @index != 3)
        @index -= 1
        pbSEPlay("Choose")
        refresh
      end
      if Input.trigger?(Input::UP) && @index >= 3
        @index -= 3
        pbSEPlay("Choose")
        refresh
      end
      if Input.trigger?(Input::DOWN) && @index <= 2 
        @index += 3
        pbSEPlay("Choose")
        refresh
      end
      #Manipulate an egg
      if Input.trigger?(Input::USE)
        if $PokemonGlobal.eggs[@index] == nil
          ret = Kernel.pbConfirmMessage("La incubadora está vacía\\n¿Quieres agregar un Huevo?")
          if ret == true
            chosen=0
            pbFadeOutIn(99999){
               scene = PokemonParty_Scene.new
               screen = PokemonPartyScreen.new(scene, $player.party)
               screen.pbStartScene(_INTL("Elige un Huevo."),false)
               chosen=screen.pbChoosePokemon
               screen.pbEndScene
            }
            if $player.party[chosen] != nil
              if !$player.party[chosen].egg?
                Kernel.pbMessage("El Pokémon elegido no es un Huevo.")
              else
                $PokemonGlobal.eggs[@index] = $player.party[chosen]
                $player.party.delete_at(chosen)
                $game_temp.bag_scene.pbHardRefresh if $game_temp && $game_temp.bag_scene && defined?($game_temp.bag_scene.pbHardRefresh)
              end
            end
          end
        else
          ret = Kernel.pbConfirmMessage("¿Quieres sacar este Huevo de la incubadora?")
          if ret == true
            takeEgg($PokemonGlobal.eggs[@index],@index)
            $game_temp.bag_scene.pbHardRefresh if $game_temp && $game_temp.bag_scene && defined?($game_temp.bag_scene.pbHardRefresh)
          end
        end
        refresh
      end
      #Close scene
      if Input.trigger?(Input::BACK)
        dispose
        Input.update
        break
      end
    
      Graphics.update
      Input.update
    end
  end
end

def takeEgg(egg,index)
  sel = Kernel.pbConfirmMessage(_INTL("¿Quieres agregarlo a tu equipo?"))
  if sel==true
    Kernel.pbMessage(_INTL("Tu equipo está lleno.\1")) if $player.party.length == 6
    pbStorePokemon(egg)
  else
    if pbBoxesFull?
      Kernel.pbMessage(_INTL("¡No hay mas espacio para Pokémon!\1"))
      Kernel.pbMessage(_INTL("¡Las cajas están llenas y no pueden recibir mas Pokémon!"))
      return
    end
    oldcurbox=$PokemonStorage.currentBox
    storedbox=$PokemonStorage.pbStoreCaught(egg)
    curboxname=$PokemonStorage[oldcurbox].name
    boxname=$PokemonStorage[storedbox].name
    if storedbox!=oldcurbox
      Kernel.pbMessage(_INTL("La caja \"{1}\" está llena.\1",curboxname))
      Kernel.pbMessage(_INTL("{1} fue transferido a la caja \"{2}.\"",egg.name,boxname))
    else
      Kernel.pbMessage(_INTL("{1} fue transferido a la caja \"{2}.\"",egg.name,boxname))
    end
  end
  $PokemonGlobal.eggs[index] = nil
end

def pbGenerateEgg(pkmn, text = "")
  return false if !pkmn || $player.party_full?
  pkmn = Pokemon.new(pkmn, Settings::EGG_LEVEL) if !pkmn.is_a?(Pokemon)
  # Set egg's details
  pkmn.name           = _INTL("Huevo")
  pkmn.steps_to_hatch = pkmn.species_data.hatch_steps
  pkmn.obtain_text    = text
  pkmn.calc_stats
  # Add egg to party
  if (GameData::Item.exists?(:EGGHATCHER) && $bag.has?(:EGGHATCHER))
    ret = Kernel.pbConfirmMessage("¿Quieres agregar el Huevo a la incubadora?")
    if ret == true
      ret = addEgg(pkmn)
      if ret == true
        return true
      end
    end
  end
  pbStorePokemon(pkmn)
  return true
end

def addEgg(egg)
  if !$PokemonGlobal.eggs
    $PokemonGlobal.eggs ||= [nil,nil,nil,nil,nil,nil]
  end
  $PokemonGlobal.eggs.each_index{|index|
    if $PokemonGlobal.eggs[index] == nil
      $PokemonGlobal.eggs[index] = egg
      return true
    end
  }
  Kernel.pbMessage("La incubadora está llena.")
  return false
end


EventHandlers.add(:on_step_taken, :incubadora, proc{|sender,e|
  next if !$player || !$PokemonGlobal.eggs
  for i in 0...$PokemonGlobal.eggs.length
   egg = $PokemonGlobal.eggs[i]
   next if egg == nil
   if egg.steps_to_hatch>0
     egg.steps_to_hatch-=1
     for poke in $player.party
       if poke.hasAbility?(:FLAMEBODY) ||
          poke.hasAbility?(:MAGMAARMOR)
         egg.steps_to_hatch-=1
         break
       end
     end
     if egg.steps_to_hatch<=0
      egg.steps_to_hatch=0
      pbHatch(egg)
      takeEgg(egg,i)
     end
   end
  end
})


def openHatcher
  scene = Hatcher.new
  scene.update
end


ItemHandlers::UseFromBag.add(:EGGHATCHER,proc{|item|
  pbFadeOutIn(99999){
    openHatcher
  }
  next 1
})


ItemHandlers::UseInField.add(:EGGHATCHER,proc{|item|
  pbFadeOutIn(99999){
    openHatcher
  }
  next 1
})



