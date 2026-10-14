# SSH-туннели

Apache на `ws22` привязан к loopback и напрямую из сети недоступен:

```apache
Listen 127.0.0.1:80
```

![Apache слушает loopback](images/apache-loopback.png)

## Local port forwarding

На `ws21` локальный порт `8080` направлен через SSH к loopback-порту Apache на `ws22`:

```bash
ssh -L 8080:localhost:80 morynkar@10.20.0.20 -p2022
```

Короткая опция OpenSSH допускает как `-p2022`, так и `-p 2022`; в документации сохранена фактически использованная форма.

![Создание local tunnel](images/ssh-local-tunnel.png)

```bash
curl http://127.0.0.1:8080
```

![Проверка local tunnel](images/ssh-local-check.png)

## Remote port forwarding

С `ws22` создан обратный туннель к `ws11`. В результате порт `8080` на `ws11` ведёт к локальному Apache `ws22`:

```bash
ssh -R 8080:localhost:80 morynkar@10.10.0.2 -p2022
```

![Создание remote tunnel](images/ssh-remote-tunnel.png)

```bash
curl http://127.0.0.1:8080
```

![Проверка remote tunnel](images/ssh-remote-check.png)

В production-сценарии дополнительно применяются ключевая аутентификация, `ExitOnForwardFailure=yes`, ограничения `AllowTcpForwarding` и контроль адреса привязки порта.
