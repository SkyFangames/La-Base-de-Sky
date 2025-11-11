### Créditos a @Cripxoo (@pkmnAmatista) y @LaCabraPalMont (@PokemonOlympus) ###
### Requiere ajustar a placer las posiciones X e Y de los iconos ###
### Menú visual configurable de paneles a través de Switches y Variables ###
### Coloca la carpeta menu dentro de Pictures ###
### Para llamar a esta script, usa MenuPanel1.new.Panel1 y MenuPanel2.new.Panel2 ###
### Puedes crear cuantos paneles quieras, siempre y cuando cambies el nombre de la clase y el def ###

class MenuPanel1
  def Panel1
    viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    viewport.z = 999999
    sprites={}
    sprites["fondo"]=Sprite.new
    sprites["fondo"].z=99999
    sprites["fondo"].bitmap=pbBitmap("Graphics/Pictures/menu/panel1")
    sprites["overlay"]=BitmapSprite.new(Graphics.width, Graphics.height, viewport)
    
    loop do
      Graphics.update
      Input.update
      overlay=sprites["overlay"].bitmap
      overlay.clear
      color1=Color.new(255,255,255)
      color2=Color.new(0,97,127)
      color3=Color.new(30,30,0)
      color4=Color.new(180,180,180)
      pbSetSystemFont(sprites["overlay"].bitmap)
      textos=[
        [_INTL("Pruebas"),28,15,0,color1,color2],
        [_INTL("{1} / X",$game_variables[60]),400,15,0,color1,color2]
      ]
      ### Columna izquierda ###
      sprites["icono1"]=IconSprite.new(0,0,viewport)
      sprites["icono1"].x=0
      sprites["icono1"].y=40
      sprites["icono1"].visible=true
      sprites["icono2"]=IconSprite.new(0,0,viewport)
      sprites["icono2"].x=0
      sprites["icono2"].y=122
      sprites["icono2"].visible=true
      sprites["icono3"]=IconSprite.new(0,0,viewport)
      sprites["icono3"].x=0
      sprites["icono3"].y=204
      sprites["icono3"].visible=true
      sprites["icono4"]=IconSprite.new(0,0,viewport)
      sprites["icono4"].x=0
      sprites["icono4"].y=286
      sprites["icono4"].visible=true

      if $game_switches[188] == false
        textos+=[[_INTL("Mensaje Póstumo"),85,78,0,color3,color4]]
        sprites["icono1"].setBitmap("Graphics/Pictures/menu/imagen1off")
      else
        textos+=[[_INTL("Mensaje Póstumo"),85,78,0,color3,color4]]  
        sprites["icono1"].setBitmap("Graphics/Pictures/menu/imagen1")
      end
      if $game_switches[189] == false
        textos+=[[_INTL("Traumatismo"),92,161,0,color3,color4]]  
        sprites["icono2"].setBitmap("Graphics/Pictures/menu/imagen2off")
      else
        textos+=[[_INTL("Traumatismo"),92,161,0,color3,color4]] 
        sprites["icono2"].setBitmap("Graphics/Pictures/menu/imagen2")
      end
      if $game_switches[190] == false
        textos+=[[_INTL("Caja Llaves"),85,244,0,color3,color4]]
        sprites["icono3"].setBitmap("Graphics/Pictures/menu/imagen3off")
      else
        textos+=[[_INTL("Caja Llaves"),85,244,0,color3,color4]]   
        sprites["icono3"].setBitmap("Graphics/Pictures/menu/imagen3")
      end
      if $game_switches[191] == false
        textos+=[[_INTL("Arma Crimen"),92,327,0,color3,color4]]  
        sprites["icono4"].setBitmap("Graphics/Pictures/menu/imagen4off")
      else
        textos+=[[_INTL("Barra Metal"),102,327,0,color3,color4]]  
        sprites["icono4"].setBitmap("Graphics/Pictures/menu/imagen4")
      end

      ### Columna derecha ###
      sprites["icono5"]=IconSprite.new(0,0,viewport)
      sprites["icono5"].x=240
      sprites["icono5"].y=40
      sprites["icono5"].visible=true
      sprites["icono6"]=IconSprite.new(0,0,viewport)
      sprites["icono6"].x=240
      sprites["icono6"].y=122
      sprites["icono6"].visible=true
      sprites["icono7"]=IconSprite.new(0,0,viewport)
      sprites["icono7"].x=240
      sprites["icono7"].y=204
      sprites["icono7"].visible=true
      sprites["icono8"]=IconSprite.new(0,0,viewport)
      sprites["icono8"].x=240
      sprites["icono8"].y=286
      sprites["icono8"].visible=true

      if $game_switches[192] == false
        textos+=[[_INTL("Bote Pintura"),342,78,0,color3,color4]]  
        sprites["icono5"].setBitmap("Graphics/Pictures/menu/imagen5off")
      else
        textos+=[[_INTL("Bote Morado"),342,78,0,color3,color4]]   
        sprites["icono5"].setBitmap("Graphics/Pictures/menu/imagen5")
      end
      if $game_switches[193] == false
        textos+=[[_INTL("Bata"),342,161,0,color3,color4]]  
        sprites["icono6"].setBitmap("Graphics/Pictures/menu/imagen6off")
      else
        textos+=[[_INTL("Bata Manchada"),342,161,0,color3,color4]]   
        sprites["icono6"].setBitmap("Graphics/Pictures/menu/imagen6")
      end
      if $game_switches[194] == false
        textos+=[[_INTL("Uniforme XXL"),342,244,0,color3,color4]]  
        sprites["icono7"].setBitmap("Graphics/Pictures/menu/imagen7off")
      else
        textos+=[[_INTL("Uniforme Manchado"),342,244,0,color3,color4]]   
        sprites["icono7"].setBitmap("Graphics/Pictures/menu/imagen7")
      end
      if $game_switches[195] == false
        textos+=[[_INTL("Mechón largo"),342,327,0,color3,color4]]  
        sprites["icono8"].setBitmap("Graphics/Pictures/menu/imagen8off")
      else
        textos+=[[_INTL("Mechón largo"),342,327,0,color3,color4]]   
        sprites["icono8"].setBitmap("Graphics/Pictures/menu/imagen8")
      end

      pbDrawTextPositions(overlay,textos)
      if Input.trigger?(Input::B)
        pbSEPlay("select")
        pbDisposeSpriteHash(sprites)
        viewport.dispose if viewport
        break
      end
      if Input.trigger?(Input::DOWN)
        pbSEPlay("select")
        pbDisposeSpriteHash(sprites)
        viewport.dispose if viewport
        MenuPanel2.new.Panel2
        break
      end
    end
  end
end

class MenuPanel2
  def Panel2
    viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    viewport.z = 999999
    sprites={}
    sprites["fondo"]=Sprite.new
    sprites["fondo"].z=99999
    sprites["fondo"].bitmap=pbBitmap("Graphics/Pictures/menu/panel2")
    sprites["overlay"]=BitmapSprite.new(Graphics.width, Graphics.height, viewport)

    loop do
      Graphics.update
      Input.update
      overlay=sprites["overlay"].bitmap
      overlay.clear
      color1=Color.new(255,255,255)
      color2=Color.new(0,97,127)
      color3=Color.new(30,30,0)
      color4=Color.new(180,180,180)
      pbSetSystemFont(sprites["overlay"].bitmap)
      textos=[
        [_INTL("Pruebas"),28,15,0,color1,color2],
        [_INTL("{1} / X",$game_variables[60]),400,15,0,color1,color2]
      ]

      ### Columna izquierda ###
      sprites["icono1"]=IconSprite.new(0,0,viewport)
      sprites["icono1"].x=0
      sprites["icono1"].y=40
      sprites["icono1"].visible=true
      sprites["icono2"]=IconSprite.new(0,0,viewport)
      sprites["icono2"].x=0
      sprites["icono2"].y=122
      sprites["icono2"].visible=true
      sprites["icono3"]=IconSprite.new(0,0,viewport)
      sprites["icono3"].x=0
      sprites["icono3"].y=204
      sprites["icono3"].visible=true
      sprites["icono4"]=IconSprite.new(0,0,viewport)
      sprites["icono4"].x=0
      sprites["icono4"].y=286
      sprites["icono4"].visible=true

      if $game_switches[196] == false
        textos+=[[_INTL("Conducto"),102,78,0,color3,color4]]
        sprites["icono1"].setBitmap("Graphics/Pictures/menu/imagen9off")
      else
        textos+=[[_INTL("Conducto Usado"),104,78,0,color3,color4]]  
        sprites["icono1"].setBitmap("Graphics/Pictures/menu/imagen9")
      end
      if $game_switches[197] == false
        textos+=[[_INTL("Trébol 4 Hojas"),102,161,0,color3,color4]]  
        sprites["icono2"].setBitmap("Graphics/Pictures/menu/imagen10off")
      else
        textos+=[[_INTL("Trébol 4 Hojas"),102,161,0,color3,color4]] 
        sprites["icono2"].setBitmap("Graphics/Pictures/menu/imagen10")
      end
      if $game_switches[198] == false
        textos+=[[_INTL("Plano Sótano"),102,244,0,color3,color4]]
        sprites["icono3"].setBitmap("Graphics/Pictures/menu/imagen11off")
      else
        textos+=[[_INTL("Plano Sótano"),102,244,0,color3,color4]]   
        sprites["icono3"].setBitmap("Graphics/Pictures/menu/imagen11")
      end

      ### Columna derecha ###
      sprites["icono5"]=IconSprite.new(0,0,viewport)
      sprites["icono5"].x=240
      sprites["icono5"].y=40
      sprites["icono5"].visible=true
      sprites["icono6"]=IconSprite.new(0,0,viewport)
      sprites["icono6"].x=240
      sprites["icono6"].y=122
      sprites["icono6"].visible=true
      sprites["icono7"]=IconSprite.new(0,0,viewport)
      sprites["icono7"].x=240
      sprites["icono7"].y=204
      sprites["icono7"].visible=true
      sprites["icono8"]=IconSprite.new(0,0,viewport)
      sprites["icono8"].x=240
      sprites["icono8"].y=286
      sprites["icono8"].visible=true

      if $game_switches[199] == false
        textos+=[[_INTL("Llave Maestra"),332,78,0,color3,color4]]  
        sprites["icono5"].setBitmap("Graphics/Pictures/menu/imagen13off")
      else
        textos+=[[_INTL("LLAVE MAESTRA"),342,78,0,color3,color4]]   
        sprites["icono5"].setBitmap("Graphics/Pictures/menu/imagen13")
      end
      if $game_switches[200] == false
        textos+=[[_INTL("Plan Asesinato"),342,161,0,color3,color4]]  
        sprites["icono6"].setBitmap("Graphics/Pictures/menu/imagen14off")
      else
        textos+=[[_INTL("Cuaderno Detallado"),342,161,0,color3,color4]]   
        sprites["icono6"].setBitmap("Graphics/Pictures/menu/imagen14")
      end
      if $game_switches[201] == false
        textos+=[[_INTL("Guantes"),342,244,0,color3,color4]]  
        sprites["icono7"].setBitmap("Graphics/Pictures/menu/imagen7off")
      else
        textos+=[[_INTL("Guantes Manchados"),342,244,0,color3,color4]]   
        sprites["icono7"].setBitmap("Graphics/Pictures/menu/imagen7")
      end

      pbDrawTextPositions(overlay,textos)
      if Input.trigger?(Input::B)
        pbSEPlay("select")
        pbDisposeSpriteHash(sprites)
        viewport.dispose if viewport
        break
      end
      if Input.trigger?(Input::UP)
        pbSEPlay("select")
        pbDisposeSpriteHash(sprites)
        viewport.dispose if viewport
        MenuPanel1.new.Panel1
        break
      end
    end
  end
end
