# MT5-CRYSTAL
Crystal-lang based client for the MQL5-JSON-API ("khramkov")
Client ported from examples from https://github.com/khramkov/MQL5-JSON-API

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  zeromq:
    github: crystal-community/zeromq-crystal
  
  mt5crystal:
    github: jekroll/mt5crystal
```


## Usage


```crystal
require "zeromq"
require "mt5crystal"
```

```crystal
# Subscribe and receive tick data
socket = api.live_socket()

@api.construct_and_send({
    "action"  => "CONFIG",
    "symbol"  => "BTCEUR",
    "chartTF" => "TICK"
})

# Listen for data and parse JSON
while true
    rcv = JSON.parse( socket.receive_string() )

    sellValue = rcv[ "data" ][ 1 ].as_f
    buyValue  = rcv[ "data" ][ 2 ].as_f

    puts sellValue, buyValue
end
```

## TODO

- [ ] Add tests
- [ ] Add better documentation
- [ ] Add examples

## Contributing

1. Fork it ( https://github.com/jekroll/mt5crystal/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [jekroll](https://github.com/jekroll) José Eduardo Kroll - creator, maintainer
