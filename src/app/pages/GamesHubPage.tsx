import { useState } from 'react';

const GAMES = [
  {
    id: 'sky-metropolis',
    title: 'Sky Metropolis',
    description: 'City builder aérien futuriste',
    icon: '🏙️',
    url: '/games/sky-metropolis/index.html',
    color: '#3b82f6',
  },
  {
    id: 'voxel-art',
    title: 'Image to Voxel Art',
    description: 'Transformez vos images en art voxel',
    icon: '🎨',
    url: '/games/voxel-art/index.html',
    color: '#8b5cf6',
  },
  {
    id: 'shader-pilot',
    title: 'Shader Pilot',
    description: 'Éditeur de shaders interactif',
    icon: '🚀',
    url: '/games/shader-pilot/index.html',
    color: '#f59e0b',
  },
];

export default function GamesHubPage() {
  const [selectedGame, setSelectedGame] = useState<string | null>(null);

  if (selectedGame) {
    const game = GAMES.find((g) => g.id === selectedGame);
    if (!game) return null;

    return (
      <div className="min-h-screen bg-black flex flex-col">
        <div className="flex items-center gap-4 p-4 bg-gray-900 border-b border-gray-800">
          <button
            onClick={() => setSelectedGame(null)}
            className="px-4 py-2 bg-gray-800 hover:bg-gray-700 text-white rounded-lg transition-colors"
          >
            ← Retour
          </button>
          <h1 className="text-xl font-bold text-white">
            {game.icon} {game.title}
          </h1>
        </div>
        <div className="flex-1 w-full h-[calc(100vh-80px)]">
          <iframe
            src={game.url}
            className="w-full h-full border-0"
            title={game.title}
            allow="accelerometer; camera; gyroscope; microphone"
            allowFullScreen
          />
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-gray-900 p-8">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-white mb-4">
            🎮 Games Hub
          </h1>
          <p className="text-gray-300 text-lg">
            Découvrez nos jeux créatifs et expérimentaux
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {GAMES.map((game) => (
            <div
              key={game.id}
              onClick={() => setSelectedGame(game.id)}
              className="group relative bg-gray-800/50 backdrop-blur-sm rounded-2xl p-6 cursor-pointer transform transition-all duration-300 hover:scale-105 hover:shadow-2xl border border-gray-700 hover:border-gray-500"
            >
              <div
                className="absolute inset-0 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                style={{
                  background: `linear-gradient(135deg, ${game.color}20, transparent)`,
                }}
              />

              <div className="relative z-10">
                <div className="text-6xl mb-4 transform group-hover:scale-110 transition-transform duration-300">
                  {game.icon}
                </div>

                <h3 className="text-2xl font-bold text-white mb-2">
                  {game.title}
                </h3>

                <p className="text-gray-300 mb-4">
                  {game.description}
                </p>

                <div className="flex items-center text-sm font-medium" style={{ color: game.color }}>
                  <span>Jouer maintenant</span>
                  <svg
                    className="w-4 h-4 ml-2 transform group-hover:translate-x-1 transition-transform"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="mt-12 text-center text-gray-400 text-sm">
          <p>💡 Les jeux sont optimisés pour Chrome et Edge</p>
        </div>
      </div>
    </div>
  );
}