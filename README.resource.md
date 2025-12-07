# rev-core example framework

Lekki zasób prezentujący podstawową warstwę Core z callbackami klient-serwer oraz użytecznymi funkcjami.

## Struktura
- `server/characters.lua` – przykładowa warstwa postaci/bazy, CRUD na postaciach i aktualizacja `Core.Player` na kliencie.
- Eventy `rev-core:getSharedObject` / `rev-core:updateSharedObject` pozwalają innym zasobom uzyskać obiekt Core (jak w `es_extended`).

## Rejestracja callbacków
```lua
-- serwer
Core.Callbacks.Server:RegisterCallback('get-money', function(src, targetId)
    local money = 1000
    return money, targetId
end)

-- klient
Core.Callbacks.Client:RegisterCallback('fetch-name', function()
    return GetPlayerName(PlayerId())
end)
```

## Wywoływanie
```lua
-- klient -> serwer (async)
Core.Callbacks.Server.Async('get-money', function(money, targetId)
    print('Money from server', money, targetId)
end, 27)

-- klient -> serwer (await)
local money, targetId = Core.Callbacks.Server.Await('get-money', 27)
print('Money from server', money, targetId)

-- serwer -> klient (async)
Core.Callbacks.Client.Async('fetch-name', targetSource, function(name)
    print('Client name', name)
end)

-- serwer -> klient (await)
local name = Core.Callbacks.Client.Await('fetch-name', targetSource)
print('Client name', name)
```

## Postacie / baza
```lua
-- pobranie listy postaci (klient)
Core.Callbacks.Server.Await('characters:get')

-- utworzenie nowej postaci
Core.Callbacks.Server.Async('characters:create', function(character)
    print(json.encode(character))
end, {
    firstname = 'Lester',
    lastname = 'Crest',
    job = 'hacker',
    cash = 500
})

-- wybór konkretnej postaci
Core.Callbacks.Server.Await('characters:select', '123')

-- usunięcie postaci
Core.Callbacks.Server.Await('characters:delete', '123')

-- zapis pola w aktualnej postaci
Core.Callbacks.Server.Await('characters:saveValue', 'job', 'police')
```

## Utils
- `ArrayRemove(array, predicate)` – stabilne usuwanie elementów tablicy na podstawie predykatu.
- `CopyTable(source, destination)` – głębokie kopiowanie z zachowaniem referencji funkcji CFX.
- `MathRound(number, precision?)` – zaokrąglanie do zadanej precyzji.
- `FormatDate(timestamp, includeTime?)` – formatowanie daty.
- `FormatFromMilliseconds(ms)` / `FormatToMilliseconds(h, m, s)` – konwersja czasu.
- `HasJob(jobName, requireDuty?)` / `HasJobFromCategory(category)` – wygodne helpery klienckie.
- `Core.Print(...)` – ładne logowanie JSONem z nazwą zasobu.
