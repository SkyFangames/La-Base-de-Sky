#===============================================================================
# Mystery Gift system
# By Maruno
#===============================================================================
# This url is the location of an example Mystery Gift file.
# You should change it to your file's url once you upload it.
#===============================================================================
module MysteryGift
  URL = "https://pastebin.com/raw/VRDjyp8q"
end

#===============================================================================
# Creating a new Mystery Gift for the Master file, and editing an existing one.
#===============================================================================
# type: 0=Pokémon; 1 or higher=item (is the item's quantity).
# item: The thing being turned into a Mystery Gift (Pokémon object or item ID).
def pbEditMysteryGift(type, item, id = 0, giftname = "", password = nil)
  begin
    if type == 0   # Pokémon
      commands = [_INTL("Regalo Misterioso"),
                  _INTL("Lugar lejano")]
      commands.push(item.obtain_text) if item.obtain_text && !item.obtain_text.empty?
      commands.push(_INTL("[Custom]"))
      loop do
        command = pbMessage(
          _INTL("Elige una frase sobre el lugar donde se ha obtenido ese Pokémon."),
          commands, -1
        )
        if command < 0
          return nil if pbConfirmMessage(_INTL("¿Dejar de agregar este regalo?"))
        elsif command < commands.length - 1
          item.obtain_text = commands[command]
          break
        elsif command == commands.length - 1
          obtainname = pbMessageFreeText(_INTL("Introduce una frase."), "", false, 30)
          if obtainname != ""
            item.obtain_text = obtainname
            break
          end
          return nil if pbConfirmMessage(_INTL("¿Dejar de agregar este regalo?"))
        end
      end
    elsif type > 0   # Item
      params = ChooseNumberParams.new
      params.setRange(1, 99_999)
      params.setDefaultValue(type)
      params.setCancelValue(0)
      loop do
        newtype = pbMessageChooseNumber(_INTL("Elige la cantidad de {1}.",
                                              GameData::Item.get(item).name), params)
        if newtype == 0
          return nil if pbConfirmMessage(_INTL("¿Dejar de editar este regalo?"))
        else
          type = newtype
          break
        end
      end
    end
    if id == 0
      master = []
      idlist = []
      if FileTest.exist?("MysteryGiftMaster.txt")
        master = IO.read("MysteryGiftMaster.txt")
        master = pbMysteryGiftDecrypt(master)
      end
      master.each do |i|
        idlist.push(i[0])
      end
      params = ChooseNumberParams.new
      params.setRange(0, 99_999)
      params.setDefaultValue(id)
      params.setCancelValue(0)
      loop do
        newid = pbMessageChooseNumber(_INTL("Elige un ID único para este regalo."), params)
        if newid == 0
          return nil if pbConfirmMessage(_INTL("¿Dejar de editar este regalo?"))
        elsif idlist.include?(newid)
          pbMessage(_INTL("Ese ID ya está en uso por un Regalo Misterioso."))
        else
          id = newid
          break
        end
      end
    end
    loop do
      newgiftname = pbMessageFreeText(_INTL("Introduce un nombre para el regalo."), giftname, false, 250)
      if newgiftname != ""
        giftname = newgiftname
        break
      end
      return nil if pbConfirmMessage(_INTL("¿Dejar de editar este regalo?"))
    end
    # Pedir si el regalo tendrá contraseña
    has_password = pbConfirmMessage(_INTL("¿Quieres que este regalo requiera una contraseña?"))
    if has_password
      loop do
        new_password = pbMessageFreeText(_INTL("Introduce una contraseña de 8 caracteres."), "", false, 8)
        if new_password.length == 8
          password = new_password
          break
        else
          pbMessage(_INTL("La contraseña debe tener exactamente 8 caracteres."))
        end
      end
    end
    return [id, type, item, giftname, password]
  rescue
    pbMessage(_INTL("No se puede agregar el regalo."))
    return nil
  end
end

def pbCreateMysteryGift(type, item)
  gift = pbEditMysteryGift(type, item)
  if gift
    begin
      if FileTest.exist?("MysteryGiftMaster.txt")
        master = IO.read("MysteryGiftMaster.txt")
        master = pbMysteryGiftDecrypt(master)
        master.push(gift)
      else
        master = [gift]
      end
      string = pbMysteryGiftEncrypt(master)
      File.open("MysteryGiftMaster.txt", "wb") { |f| f.write(string) }
      pbMessage(_INTL("El regalo se ha guardado en MysteryGiftMaster.txt."))
    rescue
      pbMessage(_INTL("No se ha podido guardar el regalo en MysteryGiftMaster.txt."))
    end
  else
    pbMessage(_INTL("No se ha creado el regalo."))
  end
end

#===============================================================================
# Debug option for managing gifts in the Master file and exporting them to a
# file to be uploaded.
#===============================================================================
def pbManageMysteryGifts
  if !FileTest.exist?("MysteryGiftMaster.txt")
    pbMessage(_INTL("No se encuentra el archivo \"MysteryGiftMaster.txt\" con los Regalos Misteriosos. No has creado ningún regalo."))
    pbMessage(_INTL("Puedes crear Regalos tanto de Pokémon como de Objetos. Para los Pokémon, elige la opción Debug que aparece al seleccionarlos en tu equipo o en el PC. Para los Objetos, elige la opción Debug que aparece al seleccionarlos en la Mochila."))
    pbMessage(_INTL("Una vez creados de ese modo, podrás encontrarlos aquí para gestionarlos y subirlos a Internet."))
    return
  end
  # Load all gifts from the Master file.
  master = IO.read("MysteryGiftMaster.txt")
  master = pbMysteryGiftDecrypt(master)
  if !master || !master.is_a?(Array) || master.length == 0
    pbMessage(_INTL("No hay Regalos Misteriosos definidos en el archivo \"MysteryGiftMaster.txt\". No has creado ninguno."))
    pbMessage(_INTL("Puedes crear Regalos tanto de Pokémon como de Objetos. Para los Pokémon, elige la opción Debug que aparece al seleccionarlos en tu equipo o en el PC. Para los Objetos, elige la opción Debug que aparece al seleccionarlos en la Mochila."))
    pbMessage(_INTL("Una vez creados de ese modo, podrás encontrarlos aquí para gestionarlos y subirlos a Internet."))
    return
  end
  pbMessage(_INTL("Archivo \"MysteryGiftMaster.txt\" leído correctamente con los Regalos Misteriosos."))
  # Download all gifts from online
  msgwindow = pbCreateMessageWindow
  pbMessageDisplay(msgwindow, _INTL("Buscando ahora regalos misteriosos en el enlace en línea..."))
  begin
    online = pbDownloadToString(MysteryGift::URL)
  rescue MKXPError
    online = nil
    pbMessage(_INTL("Parece que no tienes conexión a Internet, por lo que no se han podido buscar los regalos.\\wtnp[20]"))
    return
  end
  pbDisposeMessageWindow(msgwindow)
  if nil_or_empty?(online)
    pbMessage(_INTL("No se han encontrado Regalos Misteriosos en el enlace de Internet tras la descarga. Parece que está vacío.\\wtnp[20]"))
    online = []
  else
    pbMessage(_INTL("Se han encontrado Regalos Misteriosos en el enlace de Internet.\\wtnp[20]"))
    online = pbMysteryGiftDecrypt(online, false)
    t = []
    online.each { |gift| t.push(gift[0]) }
    online = t
  end
  # Show list of all gifts.
  command = 0
  loop do
    commands = pbRefreshMGCommands(master, online)
    command = pbMessage("\\ts[]" + _INTL("Gestionar los Regalos Misteriosos (X = regalo encontrado ya en internet)."), commands, -1, nil, command)
    # Gift chosen
    if command == -1 || command == commands.length - 1   # Cancel
      break
    elsif command == commands.length - 4   # Export selected to file
      begin
        newfile = []
        master.each do |gift|
          newfile.push(gift) if online.include?(gift[0])
        end
        string = pbMysteryGiftEncrypt(newfile, false)
        File.open("MysteryGift.txt", "wb") { |f| f.write(string) }
        pbMessage(_INTL("Los regalos que has marcado con una X se han guardado en el archivo MysteryGift.txt."))
        pbMessage(_INTL("Ahora debes subir el contenido del archivo MysteryGift.txt a tu enlace de Internet (por ejemplo en la web de Pastebin) para que puedan ser descargados."))
      rescue
        pbMessage(_INTL("No se han podido guardar los datos en el archivo MysteryGift.txt. Inténtalo de nuevo."))
      end
    elsif command == commands.length - 3   # Borrar los regalos recibidos
      if pbConfirmMessage(_INTL("¿Quieres eliminar el registro de tu jugaror de regalos misteriosos? Esto hará que puedas recibirlos todos de nuevo."))
        $player.mystery_gifts = []
        pbMessage(_INTL("Has eliminado correctamente los regalos recibidos."))

      end
    elsif command == commands.length - 2   # A gift
      pbMessage(_INTL("Este menú sirve para gestionar los Regalos Misteriosos."))
      pbMessage(_INTL("Los regalos marcados con una X al entrar en el menú son los que están en internet. El resto son los que están en el archivo \"MysteryGiftMaster.txt\"."))
      pbMessage(_INTL("Ten en cuenta que lo que busca es que en Internet haya un regalo con la misma ID que ese que has elegido. El contenido puede ser distinto, pero si comparten ID aparecerá igualmente marcado."))
      pbMessage(_INTL("Hay dos formas de crear un regalo de la nada: si es un Pokémon, selecciónalo en tu equipo o en el PC y elige la opción Debug. Ahí dentro verás la opción de convertirlo en Regalo Misterioso."))
      pbMessage(_INTL("Lo ideal es que edites un poco el Pokémon antes de crearlo y después elijas esta opción."))
      pbMessage(_INTL("La otra forma de crear los regalos es a partir de un objeto. Añádete el item que te interese desde el modo Debug a la mochila. Después, selecciona ese item dentro de la mochila y elige la opcion Debug y después Hacer Regalo Mist., y sigue los pasos que se indican."))
      pbMessage(_INTL("Una vez creados, al entrar en este menú verás que aparecen aquí, ya que se han guardado en el archivo \"MysteryGiftMaster.txt\"."))
      pbMessage(_INTL("En este menú, marca y desmarca los que quieras y después dale a \"Exportar elegidos\" para escribir los seleccionados en el archivo \"MysteryGift.txt\", que es un archivo distinto, y así poder subirlos a internet."))
      pbMessage(_INTL("Una vez hecho eso, copia y pega el contenido del archivo \"MysteryGift.txt\" en el enlace que hayas creado."))
      pbMessage(_INTL("Puedes usar servicios como la web de Pastebin para subir ahí tus regalos y que así tus jugadores puedan descargarlos."))
      pbMessage(_INTL("Recuerda que debes poner la URL de tu Pastebin en el script \"UI_MysteryGift\" dentro de los scripts del juego, a los que se accede desde el editor."))
      pbMessage(_INTL("Puedes encontrarlo rápidamente si entras en el editor de scripts, pulsas \"cntrl + shift + F\" y escribes \"module MysteryGift\"."))
      pbMessage(_INTL("¡IMPORTANTE! En el archibo \"MysteryGiftMaster.txt\" se pueden leer todos los datos de tus regalos y sus contraseñas. Te recomiendo que lo elimines de la carpeta del juego cuando lo vayas a compartir, para que nadie tenga acceso al mismo."))
    elsif command >= 0 && command < commands.length - 4   # A gift
      cmd = 0
      loop do
        commands = pbRefreshMGCommands(master, online)
        gift = master[command]
        cmds = [_INTL("Marcar/desmarcar regalo"),
                _INTL("Editar el regalo"),
                _INTL("Recibir el regalo"),
                _INTL("Eliminar el regalo"),
                _INTL("Cancelar")]
        cmd = pbMessage("\\ts[]" + commands[command], cmds, -1, nil, cmd)
        case cmd
        when -1, cmds.length - 1
          break
        when 0   # Toggle on/offline
          if online.include?(gift[0])
            online.delete(gift[0])
          else
            online.push(gift[0])
          end
        when 1   # Edit
          password = gift[4] || nil
          newgift = pbEditMysteryGift(gift[1], gift[2], gift[0], gift[3], password)
          master[command] = newgift if newgift
        when 2   # Receive
          if !$player
            pbMessage(_INTL("No hay ninguna partida guardada cargada. No se puede recibir ningún regalo."))
            next
          end
          replaced = false
          $player.mystery_gifts.length.times do |i|
            if $player.mystery_gifts[i][0] == gift[0]
              $player.mystery_gifts[i] = gift
              replaced = true
            end
          end
          $player.mystery_gifts.push(gift) if !replaced
          pbReceiveMysteryGift(gift[0])
        when 3   # Delete
          if pbConfirmMessage(_INTL("¿Estás seguro de que quieres borrar este regalo? Se eliminará del archivo \"MysteryGiftMaster.txt\"."))
            master.delete_at(command)
            begin
              newfile = []
              master.each do |gift|
                newfile.push(gift)
              end
              string = pbMysteryGiftEncrypt(newfile)
              File.open("MysteryGiftMaster.txt", "wb") { |f| f.write(string) }
              pbMessage(_INTL("El regalo se ha eliminado correctamente del archivo \"MysteryGiftMaster.txt\"."))  
            rescue
              pbMessage(_INTL("No se han podido guardar los datos en el archivo \"MysteryGiftMaster.txt\". Inténtalo de nuevo."))
            end
          end
          break
        end
      end
    end
  end
end

def pbRefreshMGCommands(master, online)
  commands = []
  master.each do |gift|
    itemname = "BLANK"
    if gift[1] == 0
      itemname = gift[2].speciesName
    elsif gift[1] > 0
      itemname = GameData::Item.get(gift[2]).name + sprintf(" x%d", gift[1])
    end
    ontext = ["[  ]", "[X]"][(online.include?(gift[0])) ? 1 : 0]
    commands.push(_INTL("{1} {2}: {3} ({4})", ontext, gift[0], gift[3], itemname))
  end
  commands.push(_INTL("-> Exportar elegidos a archivo"))
  commands.push(_INTL("-> Eliminar regalos del jugador"))
  commands.push(_INTL("-> Ayuda sobre cómo funciona"))
  commands.push(_INTL("Cancelar"))
  return commands
end

#===============================================================================
# Downloads all available Mystery Gifts that haven't been downloaded yet.
#===============================================================================
# Called from the Continue/New Game screen.
def pbDownloadMysteryGift(trainer)
  sprites = {}
  @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  @viewport.z = 99999
  addBackgroundPlane(sprites, "background", "mysterygift_bg", @viewport)
  pbFadeInAndShow(sprites)
  pbBGMPlay("Regalo Misterioso", 70)
  loop do
    # Menú de opciones: regalos con contraseña o sin contraseña
    command = pbMessage("Elige qué tipo de Regalo Misterioso descargar.", [
          _INTL("Sin contraseña"),
          _INTL("Con contraseña"),
          _INTL("Cancelar")
      ], -1)
    case command
    when 0
      # Buscar regalos sin contraseña (el flujo original)
      pbDownloadGiftWithoutPassword(trainer)
    when 1
      # Buscar regalos con contraseña
      pbDownloadGiftWithPassword(trainer)
    when 2, -1
      break
    end
  end
  pbBGMFade(1.0)
  pbFadeOutAndHide(sprites)
  pbDisposeSpriteHash(sprites)
  @viewport.dispose
end




def pbDownloadGiftWithoutPassword(trainer)
  # Descargar la lista de regalos desde el servidor usando la URL correcta
  pbMessage(_INTL("Buscando regalos en línea...\\wtnp[20]"))
  begin
    data = pbDownloadToString(MysteryGift::URL)
  rescue MKXPError
    pbMessage(_INTL("Parece que no tienes conexión a Internet, No se pueden buscar regalos."))
    return
  end
  if !data
    pbMessage(_INTL("No se pudo descargar la lista de regalos."))
    return
  end
  # Desencriptar los datos recibidos
  online = pbMysteryGiftDecrypt(data, false)
  pending = []
  online.each do |gift|
    notgot = true
    trainer.mystery_gifts.each do |j|
      notgot = false if j[0] == gift[0]
    end
    pending.push(gift) if notgot
  end
  if pending.length == 0
    pbMessage(_INTL("No hay nuevos regalos disponibles."))
    return
  end

  # Filtrar solo los regalos que no tienen contraseña
  gifts_without_password = pending.select { |gift| gift.length == 4 || (gift.length == 5 && (gift[4].nil? || gift[4].empty?)) }
  # Verificar si hay regalos sin contraseña disponibles
  if gifts_without_password.empty?
    pbMessage(_INTL("No hay regalos disponibles."))
    return
  end
  # Mostrar al jugador la lista de regalos disponibles sin contraseña
  commands = []
  gifts_without_password.each do |gift|
    commands.push(_INTL("{1}", gift[3]))  # gift[3] es el nombre del regalo, gift[0] es el ID
  end
  commands.push(_INTL("Cancelar"))
  # El jugador elige un regalo para descargar
  command = pbMessage(_INTL("Elige un regalo para descargar."), commands, -1)
  if command < 0 || command >= gifts_without_password.length
    pbMessage(_INTL("No se ha descargado ningún regalo."))
    return
  end
  selected_gift = gifts_without_password[command]
  # Entregar el regalo al jugador
  pbReceiveGiftAnimation(selected_gift, trainer)
end



def pbDownloadGiftWithPassword(trainer)
  # Pedir al jugador la contraseña
  password = pbMessageFreeText(_INTL("Introduce la contraseña de 8 caracteres."), "", false, 8)
  if password.length != 8
    pbMessage(_INTL("La contraseña debe tener exactamente 8 caracteres."))
    return
  end
  pbMessage(_INTL("Buscando regalos con la contraseña indicada...\\wtnp[20]"))
  # Descargar la lista de regalos desde el servidor usando la URL
  begin
  data = pbDownloadToString(MysteryGift::URL)
  rescue MKXPError
    pbMessage(_INTL("Parece que no tienes conexión a Internet, No se pueden buscar regalos."))
    return
  end
  if !data
    pbMessage(_INTL("No se pudo descargar la lista de regalos."))
    pbMessage(_INTL("Parece que hay problemas para establecer la conexión a Internet."))
    return
  end
  # Desencriptar los datos recibidos
  online = pbMysteryGiftDecrypt(data, false)
  pending = []
  online.each do |gift|
    notgot = true
    trainer.mystery_gifts.each do |j|
      notgot = false if j[0] == gift[0]
    end
    pending.push(gift) if notgot
  end
  if pending.length == 0
    pbMessage(_INTL("No hay nuevos regalos disponibles."))
    return
  end

  # Buscar el regalo que coincida con la contraseña
  gift_found = nil
  regalos_pass = []
  pending.each do |gift|
    if gift.length == 5 && gift[4] == password  # gift[4] es la contraseña
      regalos_pass.push(gift)
      gift_found = gift
      # break
    end
  end
  # Verificar si se encontró un regalo con la contraseña proporcionada
  if gift_found.nil?
    pbMessage(_INTL("No se ha encontrado ningún regalo con esa contraseña."))
  else
    commands = []
    regalos_pass.each do |gift|
      commands.push(_INTL("{1}", gift[3]))  # gift[3] es el nombre del regalo, gift[0] es el ID
    end
    commands.push(_INTL("Cancelar"))
    # El jugador elige un regalo para descargar
    command = pbMessage(_INTL("Elige un regalo para descargar."), commands, -1)
    if command < 0 || command >= regalos_pass.length
      pbMessage(_INTL("No se ha descargado ningún regalo."))
      return
    end
    selected_gift = regalos_pass[command]
    # Entregar el regalo al jugador
    pbReceiveGiftAnimation(selected_gift, trainer)
  end
end


# Función para manejar la animación al recibir un regalo (puede ser sin o con contraseña)
def pbReceiveGiftAnimation( gift, trainer)
  if gift[1] == 0
    sprite = PokemonSprite.new(@viewport)
    sprite.setOffset(PictureOrigin::CENTER)
    sprite.setPokemonBitmap(gift[2])
    sprite.x = Graphics.width / 2
    sprite.y = -sprite.bitmap.height / 2
  else
    sprite = ItemIconSprite.new(0, 0, gift[2], @viewport)
    sprite.x = Graphics.width / 2
    sprite.y = -sprite.height / 2
  end
  timer_start = System.uptime
  start_y = sprite.y
  loop do
    sprite.y = lerp(start_y, Graphics.height / 2 + 30, 1.5, timer_start, System.uptime)
    Graphics.update
    Input.update
    sprite.update
    break if sprite.y >= Graphics.height / 2  + 30
  end
  pbMEPlay("Battle capture success")
  pbWait(3.0) {Graphics.update; sprite.update}
  pbMessage(_INTL("¡Se ha recibido el regalo!") + "\1") {Graphics.update; sprite.update}
  pbMessage(_INTL("Por favor, recoge tu regalo del repartidor de cualquier Centro Pokémon.")) {Graphics.update; sprite.update}
  trainer.mystery_gifts.push(gift)
  timer_start = System.uptime
  loop do
    sprite.opacity = lerp(255, 0, 1.5, timer_start, System.uptime)
    Graphics.update
    Input.update
    sprite.update
    break if sprite.opacity <= 0
  end
  sprite.dispose
end


#===============================================================================
# Converts an array of gifts into a string and back.
#===============================================================================
def pbMysteryGiftEncrypt(gift, master = true)
  if Settings::ENCRIPTAR_REGALOS_MISTERIOSOS_EN_MASTER || !master
    ret = [Zlib::Deflate.deflate(Marshal.dump(gift))].pack("m")
  else
    ret = gift.inspect
  end
  return ret
end

def pbMysteryGiftDecrypt(gift, master = true)
  return [] if nil_or_empty?(gift)
  if Settings::ENCRIPTAR_REGALOS_MISTERIOSOS_EN_MASTER || !master
    ret = Marshal.restore(Zlib::Inflate.inflate(gift.unpack("m")[0]))
  else
    ret = eval(gift)
  end
  if ret
    ret.each do |gft|
      if gft[1] == 0   # Pokémon
        gft[2] = gft[2]
      else   # Item
        gft[2] = GameData::Item.get(gft[2]).id
      end
    end
  end
  return ret
end

#===============================================================================
# Collecting a Mystery Gift from the deliveryman.
#===============================================================================
def pbNextMysteryGiftID
  $player.mystery_gifts.each do |i|
    return i[0] if i.length > 1
  end
  return 0
end

def pbReceiveMysteryGift(id)
  index = -1
  $player.mystery_gifts.length.times do |i|
    if $player.mystery_gifts[i][0] == id && $player.mystery_gifts[i].length > 1
      index = i
      break
    end
  end
  if index == -1
    pbMessage(_INTL("No se han encontrado regalos sin reclamar con la ID {1}.", id))
    return false
  end
  gift = $player.mystery_gifts[index]
  if gift[1] == 0   # Pokémon
    gift[2].personalID = rand(2**16) | (rand(2**16) << 16)
    gift[2].calc_stats
    gift[2].timeReceived = Time.now.to_i
    gift[2].obtain_method = 4   # Fateful encounter
    gift[2].record_first_moves
    gift[2].obtain_level = gift[2].level
    gift[2].obtain_map = $game_map&.map_id || 0
    was_owned = $player.owned?(gift[2].species)
    if pbAddPokemonSilent(gift[2])
      pbMessage(_INTL("¡{1} recibió {2}!", $player.name, gift[2].name) + "\\me[Pkmn get]\\wtnp[80]")
      $player.mystery_gifts[index] = [id]
      # Show Pokédex entry for new species if it hasn't been owned before
      if Settings::SHOW_NEW_SPECIES_POKEDEX_ENTRY_MORE_OFTEN && !was_owned &&
         $player.has_pokedex && $player.pokedex.species_in_unlocked_dex?(gift[2].species)
        pbMessage(_INTL("Los datos de {1} se han añadido a la Pokédex.", gift[2].name))
        $player.pokedex.register_last_seen(gift[2])
        pbFadeOutIn do
          scene = PokemonPokedexInfo_Scene.new
          screen = PokemonPokedexInfoScreen.new(scene)
          screen.pbDexEntry(gift[2].species)
        end
      end
      return true
    end
  elsif gift[1] > 0   # Item
    item = gift[2]
    qty = gift[1]
    if $bag.can_add?(item, qty)
      $bag.add(item, qty)
      itm = GameData::Item.get(item)
      itemname = (qty > 1) ? itm.portion_name_plural : itm.portion_name
      if item == :DNASPLICERS
        pbMessage("\\me[Item get]" + _INTL("¡Has obtenido \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
      elsif itm.is_machine?   # TM or HM
        if qty > 1
          pbMessage("\\me[Machine get]" + _INTL("¡Has obtenido {1} \\c[1]{2} {3}\\c[0]!",
                                                qty, itemname, GameData::Move.get(itm.move).name) + "\\wtnp[70]")
        else
          pbMessage("\\me[Machine get]" + _INTL("¡Has obtenido \\c[1]{1} {2}\\c[0]!", itemname,
                                                GameData::Move.get(itm.move).name) + "\\wtnp[70]")
        end
      elsif qty > 1
        pbMessage("\\me[Item get]" + _INTL("¡Has obtenido {1} \\c[1]{2}\\c[0]!", qty, itemname) + "\\wtnp[40]")
      elsif itemname.starts_with_vowel?
        pbMessage("\\me[Item get]" + _INTL("¡Has obtenido \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
      else
        pbMessage("\\me[Item get]" + _INTL("¡Has obtenido \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
      end
      $player.mystery_gifts[index] = [id]
      return true
    end
  end
  return false
end
