# Gaming profile

The host can improve loaded latency and service responsiveness, but the largest source of idle RTT is the network path from the player to the VPS and then to the game server.

For gaming, benchmark:

1. Player → VPN endpoint idle RTT.
2. Player → VPN endpoint while a large download runs.
3. VPS → game IP using MTR.
4. Direct Xray outbound vs WARP outbound if WARP is experimentally enabled.
5. UDP tunnel (WireGuard/Hysteria-class transport) vs TCP/WS for games that use UDP.

Do not interpret a lower `ping 1.1.1.1` as proof that a game server will improve. Use the real game endpoint or a reliable regional test target.
