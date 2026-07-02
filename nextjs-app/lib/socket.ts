import { io, type Socket } from "socket.io-client";

const SOCKET_URL =
  process.env.NEXT_PUBLIC_SOCKET_URL ?? "http://localhost:5000";

let _socket: Socket | null = null;

export function getSocket(): Socket {
  if (typeof window === "undefined") {
    throw new Error("getSocket() must be called client-side only");
  }
  if (!_socket) {
    _socket = io(SOCKET_URL, {
      path: "/socket.io",
      transports: ["websocket", "polling"],
      autoConnect: false,
      reconnection: true,
      reconnectionDelay: 2000,
      reconnectionAttempts: 10,
    });
  }
  return _socket;
}
