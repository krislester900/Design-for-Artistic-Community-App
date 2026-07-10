import { useMemo, useState } from "react";
import type { OntologyConcept, OntologyRelation } from "../services/ontology";

const CATEGORY_COLORS: Record<string, string> = {
  technique: "#8b5cf6",
  style: "#ec4899",
  mouvement: "#f59e0b",
  medium: "#06b6d4",
  outil: "#10b981",
  theorie: "#6366f1",
  genre: "#f97316",
  format: "#14b8a6",
  artiste: "#ef4444",
  oeuvre: "#a855f7",
};

interface GraphNode {
  id: number;
  slug: string;
  label: string;
  category: string;
  x: number;
  y: number;
}

interface GraphEdge {
  source: number;
  target: number;
  type: string;
  weight: number;
}

interface Props {
  concepts: OntologyConcept[];
  relations: OntologyRelation[];
  selectedSlug?: string;
  onSelectConcept: (concept: OntologyConcept) => void;
}

export function OntologyGraph({ concepts, relations, selectedSlug, onSelectConcept }: Props) {
  const [dragging, setDragging] = useState<number | null>(null);
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });

  const showLabels = concepts.length <= 20;

  const nodes: GraphNode[] = useMemo(() => {
    const centerX = 400;
    const centerY = 300;
    const radius = Math.min(centerX, centerY) - 60;
    return concepts.map((c, i) => {
      const angle = (2 * Math.PI * i) / concepts.length - Math.PI / 2;
      return {
        id: c.id,
        slug: c.slug,
        label: c.label,
        category: c.category,
        x: c.id === dragging ? c.x : centerX + radius * Math.cos(angle),
        y: c.id === dragging ? c.y : centerY + radius * Math.sin(angle),
      };
    });
  }, [concepts, dragging]);

  const edges: GraphEdge[] = useMemo(() => {
    const nodeIds = new Set(concepts.map((c) => c.id));
    return relations
      .filter((r) => nodeIds.has(r.source_id) && nodeIds.has(r.target_id))
      .map((r) => ({
        source: r.source_id,
        target: r.target_id,
        type: r.relation_type,
        weight: r.weight,
      }));
  }, [concepts, relations]);

  const nodeMap = useMemo(() => {
    const map = new Map<number, GraphNode>();
    for (const n of nodes) map.set(n.id, n);
    return map;
  }, [nodes]);

  if (concepts.length === 0) {
    return (
      <div className="flex h-[400px] items-center justify-center rounded-2xl border border-dashed border-border/50 text-sm text-muted-foreground">
        Aucun concept à afficher
      </div>
    );
  }

  return (
    <div className="relative overflow-hidden rounded-2xl border border-border/50 bg-card/30">
      <svg viewBox="0 0 800 600" className="h-full w-full">
        <defs>
          {Object.entries(CATEGORY_COLORS).map(([key, color]) => (
            <radialGradient key={key} id={`glow-${key}`}>
              <stop offset="0%" stopColor={color} stopOpacity="0.3" />
              <stop offset="100%" stopColor={color} stopOpacity="0" />
            </radialGradient>
          ))}
        </defs>

        {edges.map((edge, i) => {
          const source = nodeMap.get(edge.source);
          const target = nodeMap.get(edge.target);
          if (!source || !target) return null;
          return (
            <line
              key={`edge-${i}`}
              x1={source.x}
              y1={source.y}
              x2={target.x}
              y2={target.y}
              stroke="currentColor"
              strokeWidth={0.5 + edge.weight}
              opacity={0.2 + edge.weight * 0.4}
              className="text-muted-foreground"
            />
          );
        })}

        {nodes.map((node) => {
          const color = CATEGORY_COLORS[node.category] ?? "#888";
          const isSelected = node.slug === selectedSlug;
          return (
            <g key={node.id}>
              <circle
                cx={node.x}
                cy={node.y}
                r={isSelected ? 32 : 24}
                fill={`url(#glow-${node.category})`}
                opacity={0.5}
              />
              <circle
                cx={node.x}
                cy={node.y}
                r={isSelected ? 22 : 16}
                fill={color}
                opacity={0.15}
                stroke={isSelected ? color : `${color}80`}
                strokeWidth={isSelected ? 3 : 2}
                className="cursor-pointer transition-all"
                onClick={() => {
                  const c = concepts.find((cc) => cc.id === node.id);
                  if (c) onSelectConcept(c);
                }}
              />
              <text
                x={node.x}
                y={node.y + 1}
                textAnchor="middle"
                dominantBaseline="middle"
                fontSize={12}
                fill={color}
                className="pointer-events-none select-none"
              >
                {concepts.find((c) => c.id === node.id)?.icon ?? "●"}
              </text>
              {showLabels && (
                <text
                  x={node.x}
                  y={node.y + (isSelected ? 44 : 34)}
                  textAnchor="middle"
                  fontSize={isSelected ? 11 : 10}
                  fill="currentColor"
                  opacity={isSelected ? 1 : 0.7}
                  className="pointer-events-none select-none text-muted-foreground"
                >
                  {node.label.length > 15
                    ? node.label.slice(0, 14) + "…"
                    : node.label}
                </text>
              )}
            </g>
          );
        })}
      </svg>
    </div>
  );
}
