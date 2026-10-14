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
    option domain-name-servers 1.1.1.1;
}
```

Адрес `10.20.0.20` исключён из пула, поскольку статически назначен веб-серверу `ws22`.

Полный пример находится в [`configs/dhcp/r2-dhcpd.conf`](../configs/dhcp/r2-dhcpd.conf).

![Конфигурация DHCP на r2](images/dhcp-r2-config.png)

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

На `r1` создано закрепление адреса:

```dhcpd
host ws11 {
    hardware ethernet 10:10:10:10:10:ba;
    fixed-address 10.10.0.2;
}
```

![DHCP reservation](images/dhcp-reservation.png)

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

## Результат

`ws21` получает адрес из динамического пула `r2`, а `ws11` стабильно получает `10.10.0.2` от `r1` благодаря reservation. Статический адрес `ws22` исключён из пула, поэтому DHCP не может выдать его другому клиенту.

---

[← Предыдущий этап: маршрутизация](routing.md) | [Следующий этап: NAT →](nat.md)
