import { useEffect, useRef } from 'react';
import { io } from 'socket.io-client';

let socket = null;

export function useSocket() {
  const socketRef = useRef(null);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) return;

    if (!socket) {
      const apiUrl = import.meta.env.VITE_API_URL;
      const socketUrl = apiUrl === '/api'
        ? window.location.origin
        : apiUrl?.replace(/\/api\/?$/, '') || 'http://localhost:5000';
      socket = io(socketUrl, {
        auth: { token },
      });
    }
    socketRef.current = socket;

    return () => {
      // Don't disconnect on unmount — keep persistent connection
    };
  }, []);

  return socketRef;
}
