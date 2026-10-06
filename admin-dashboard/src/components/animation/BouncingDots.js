import React, { useState, useEffect } from 'react';

const LoadingBouncingDot = ({ color = '#000', size = 20 }) => {
  const [activeDot, setActiveDot] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setActiveDot((activeDot) => (activeDot + 1) % 4);
    }, 300);

    return () => clearInterval(interval);
  }, []);

  const dots = Array.from({ length: 4 }, (_, i) => (
    <div
      key={i}
      style={{
        backgroundColor: i === activeDot ? color : 'gray',
        width: size,
        height: size,
        borderRadius: '50%',
        margin: '0 5px',
        opacity: i === activeDot ? 1 : 0.4,
        animation: 'bounce 0.5s ease-in-out infinite alternate',
      }}
    />
  ));

  return <div style={{ display: 'flex', justifyContent: 'center' }}>{dots}</div>;
};

export default LoadingBouncingDot;
