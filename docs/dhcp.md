# DHCP

[← README](../README.md) · [Топология](topology.md) · [Адресация](addressing.md) · [Firewall](firewall.md) · [Маршрутизация](routing.md) · **DHCP** · [NAT](nat.md) · [SSH-туннели](ssh-tunnels.md)

---

## Цель этапа

Заменить ручное назначение адресов автоматической конфигурацией клиентов. Одновременно проверяются два сценария: свободная выдача адреса из пула и закрепление постоянного адреса за известным MAC.

DHCP-серверы развёрнуты на обоих маршрутизаторах. `r2` выдаёт динамические адреса узлам LAN 2, а `r1` закрепляет постоянный адрес `ws11` по MAC.

## Динамический пул

Основные параметры для сети `10.20.0.0/26`:

```dhcpd
subnet 10.20.0.0 netmask 255.255.255.192 {
    range 10.20.0.2 10.20.0.19;
    range 10.20.0.21 10.20.0.50;
    option routers 10.20.0.1;
    option domain-name-servers 10.20.0.1;
}
```

На исходном лабораторном скриншоте использован единый диапазон `10.20.0.2–10.20.0.50`. В повторяемом примере адрес `10.20.0.20` исключён из пула, поскольку статически назначен веб-серверу `ws22`; это устраняет потенциальный конфликт адресов.

Полный пример находится в [`configs/dhcp/r2-dhcpd.conf`](../configs/dhcp/r2-dhcpd.conf).

![Конфигурация DHCP на r2](images/dhcp-r2-config.png)

DHCP-сервер привязан к интерфейсу LAN 2 через `/etc/default/isc-dhcp-server`:

```text
INTERFACESv4="enp0s8"
```

![Интерфейс DHCP-сервера r2](images/dhcp-r2-interface.png)

На самом маршрутизаторе проверен DNS resolver с `nameserver 8.8.8.8`.

![Настройка resolver на r2](images/dhcp-r2-resolver.png)

После перезапуска сервиса клиент получил адрес и маршрут автоматически:

```bash
sudo systemctl restart isc-dhcp-server
sudo dhclient -r enp0s3
sudo dhclient -v enp0s3
ip -4 address show enp0s3
```

![Динамический адрес клиента](images/dhcp-dynamic-client.png)

При запуске клиент выполняет обмен DHCPDISCOVER → DHCPOFFER → DHCPREQUEST → DHCPACK. В результате он получает не только IPv4-адрес, но и маску, default gateway, DNS и срок аренды.

## Reservation по MAC

На `ws11` включён DHCP и задан лабораторный MAC-адрес:

```yaml
dhcp4: true
macaddress: 10:10:10:10:10:ba
```

![Netplan клиента ws11](images/dhcp-ws11-netplan.png)

На `r1` создано закрепление адреса:

```dhcpd
host ws11 {
    hardware ethernet 10:10:10:10:10:ba;
    fixed-address 10.10.0.2;
}
```

![DHCP reservation](images/dhcp-reservation.png)

Сервер `r1` привязан к интерфейсу `enp0s3`, который смотрит в сеть `10.10.0.0/18`.

![Интерфейс DHCP-сервера r1](images/dhcp-r1-interface.png)

![Настройка resolver на r1](images/dhcp-r1-resolver.png)

![Закреплённый адрес ws11](images/dhcp-fixed-client.png)

## Обновление аренды

Для повторной проверки динамического сценария старая аренда освобождена, после чего клиент запросил новую конфигурацию:

```bash
sudo dhclient -r enp0s3
sudo dhclient -v enp0s3
```

Ключ `-r` отправляет DHCPRELEASE и удаляет текущую аренду, а `-v` показывает подробный обмен сообщениями при получении нового адреса.

![Обновление DHCP lease](images/dhcp-lease-renewal.png)

Перед запуском конфигурация проверяется без изменения состояния службы:

```bash
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf
```

## Использованные параметры DHCP

- `range` задаёт динамический пул адресов;
- `option routers` передаёт клиенту default gateway;
- `option domain-name-servers` передаёт DNS-сервер;
- `hardware ethernet` сопоставляет reservation с MAC клиента;
- `fixed-address` закрепляет конкретный IPv4-адрес;
- `default-lease-time` и `max-lease-time` управляют сроком аренды.

## Результат

`ws21` получает адрес из динамического пула `r2`, а `ws11` стабильно получает `10.10.0.2` от `r1` благодаря reservation. Статический адрес `ws22` исключён из пула, поэтому DHCP не может выдать его другому клиенту.

---

[← Предыдущий этап: маршрутизация](routing.md) | [Следующий этап: NAT →](nat.md)
