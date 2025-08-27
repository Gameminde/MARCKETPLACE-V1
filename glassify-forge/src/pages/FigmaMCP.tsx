import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { toast } from "sonner";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Separator } from "@/components/ui/separator";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { ExternalLink, LinkIcon, PlugZap, Rocket, ShieldCheck, Upload } from "lucide-react";

// Local storage keys
const LS_KEY = "figma_mcp_config";

// Types
type FigmaNode = {
  id: string;
  name: string;
  type: string;
  previewUrl?: string;
};

type Config = {
  serverUrl: string;
  figmaToken: string;
  figmaFile: string; // URL or file key
};

const defaultConfig: Config = {
  serverUrl: "",
  figmaToken: "",
  figmaFile: "",
};

function usePersistedConfig() {
  const [config, setConfig] = useState<Config>(() => {
    try {
      const raw = localStorage.getItem(LS_KEY);
      return raw ? (JSON.parse(raw) as Config) : defaultConfig;
    } catch {
      return defaultConfig;
    }
  });

  useEffect(() => {
    try {
      localStorage.setItem(LS_KEY, JSON.stringify(config));
    } catch (e) {
      // ignore
    }
  }, [config]);

  return { config, setConfig } as const;
}

// Placeholder/mocked client hooks. You can wire these to your MCP gateway later.
async function mockConnect(serverUrl: string) {
  if (!serverUrl) throw new Error("Server URL is required");
  await new Promise((r) => setTimeout(r, 400));
}

async function mockSearchNodes(query: string): Promise<FigmaNode[]> {
  await new Promise((r) => setTimeout(r, 500));
  const base = [
    { id: "1:23", name: "Home/Hero", type: "FRAME" },
    { id: "1:42", name: "Home/Features", type: "FRAME" },
    { id: "2:10", name: "Auth/Login Modal", type: "COMPONENT" },
    { id: "2:11", name: "Auth/Sign Up", type: "COMPONENT" },
  ];
  if (!query) return base;
  return base.filter((n) => n.name.toLowerCase().includes(query.toLowerCase()));
}

export default function FigmaMCP() {
  const { config, setConfig } = usePersistedConfig();
  const [connecting, setConnecting] = useState(false);
  const [connected, setConnected] = useState(false);
  const [query, setQuery] = useState("");
  const [nodes, setNodes] = useState<FigmaNode[]>([]);
  const isConfigured = useMemo(
    () => !!config.serverUrl && !!config.figmaToken && !!config.figmaFile,
    [config]
  );

  useEffect(() => {
    // attempt auto-connect if configured
    if (isConfigured && !connected) {
      handleConnect(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function handleConnect(showToast = true) {
    try {
      if (!config.serverUrl) throw new Error("Enter your MCP Gateway URL");
      if (!config.figmaToken) throw new Error("Enter your Figma token");
      if (!config.figmaFile) throw new Error("Enter your Figma file URL or key");
      setConnecting(true);
      await mockConnect(config.serverUrl);
      setConnected(true);
      showToast && toast.success("Connected to MCP gateway");
    } catch (e: any) {
      setConnected(false);
      toast.error(e?.message ?? "Failed to connect");
    } finally {
      setConnecting(false);
    }
  }

  async function handleSearch() {
    if (!connected) {
      toast.error("Connect first");
      return;
    }
    const data = await mockSearchNodes(query);
    setNodes(data);
  }

  return (
    <div className="container mx-auto p-4 md:p-8 space-y-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl md:text-4xl font-black tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-emerald-400 via-cyan-400 to-blue-400">
            Figma Context MCP
          </h1>
          <p className="text-muted-foreground mt-1">
            Configure a connection to your Figma MCP server and explore frames, components, and more.
          </p>
        </div>
        <Badge variant={connected ? "default" : "secondary"} className="shrink-0">
          <span className={`inline-flex items-center gap-2 ${connected ? "text-emerald-300" : "text-yellow-300"}`}>
            <PlugZap className="h-4 w-4" /> {connected ? "Connected" : "Not connected"}
          </span>
        </Badge>
      </div>

      <Tabs defaultValue="config" className="w-full">
        <TabsList className="glass">
          <TabsTrigger value="config">Configuration</TabsTrigger>
          <TabsTrigger value="browser" disabled={!isConfigured}>
            Browser
          </TabsTrigger>
          <TabsTrigger value="help">Help</TabsTrigger>
        </TabsList>

        <TabsContent value="config" className="space-y-4">
          <Card className="glass">
            <CardHeader>
              <CardTitle>Server & Figma</CardTitle>
              <CardDescription>
                Provide your MCP Gateway URL and Figma credentials. Values are stored locally in your browser.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">MCP Gateway URL</label>
                  <Input
                    placeholder="http://localhost:3000"
                    value={config.serverUrl}
                    onChange={(e) => setConfig((c) => ({ ...c, serverUrl: e.target.value }))}
                  />
                  <p className="text-xs text-muted-foreground">
                    The HTTP/SSE gateway that exposes your MCP server.
                  </p>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Figma Token</label>
                  <Input
                    type="password"
                    placeholder="FIGMA_PAT"
                    value={config.figmaToken}
                    onChange={(e) => setConfig((c) => ({ ...c, figmaToken: e.target.value }))}
                  />
                  <p className="text-xs text-muted-foreground">
                    Create a Personal Access Token in your Figma account settings.
                  </p>
                </div>
                <div className="space-y-2 md:col-span-2">
                  <label className="text-sm font-medium">Figma File URL or Key</label>
                  <Input
                    placeholder="https://www.figma.com/file/XXXXXXXX/Your-File"
                    value={config.figmaFile}
                    onChange={(e) => setConfig((c) => ({ ...c, figmaFile: e.target.value }))}
                  />
                </div>
              </div>

              <div className="flex items-center gap-3">
                <Button onClick={() => { toast.success("Saved locally"); }} variant="secondary">
                  Save
                </Button>
                <Button onClick={() => handleConnect()} disabled={connecting}>
                  <Rocket className="h-4 w-4 mr-2" /> {connecting ? "Connecting..." : "Connect"}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="browser" className="space-y-4">
          <Card className="glass">
            <CardHeader>
              <CardTitle>Search nodes</CardTitle>
              <CardDescription>Find frames, components, or sections in your Figma file.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex flex-col md:flex-row gap-3">
                <Input
                  placeholder="e.g. Home, Button, Header"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  onKeyDown={(e) => { if (e.key === "Enter") handleSearch(); }}
                />
                <Button onClick={handleSearch}>
                  <SearchIcon className="h-4 w-4 mr-2" /> Search
                </Button>
              </div>

              <Separator />

              {nodes.length === 0 ? (
                <div className="text-sm text-muted-foreground">No results yet. Run a search.</div>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                  {nodes.map((n) => (
                    <div key={n.id} className="glass border rounded-lg p-3 hover:bg-glass-overlay/50 transition">
                      <div className="flex items-center justify-between">
                        <div className="font-semibold truncate max-w-[70%]" title={n.name}>{n.name}</div>
                        <Badge variant="outline">{n.type}</Badge>
                      </div>
                      <div className="text-xs text-muted-foreground mt-1">ID: {n.id}</div>
                      <div className="mt-3 flex items-center gap-2">
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <Button size="sm" variant="secondary">
                              <LinkIcon className="h-4 w-4 mr-1" /> Copy link
                            </Button>
                          </TooltipTrigger>
                          <TooltipContent>Copy a deep link to this node</TooltipContent>
                        </Tooltip>
                        <Button size="sm" variant="ghost">
                          <Upload className="h-4 w-4 mr-1" /> Export
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="help" className="space-y-4">
          <Card className="glass">
            <CardHeader>
              <CardTitle>How to run the Figma MCP server</CardTitle>
              <CardDescription>Set up the server and connect it here.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4 text-sm">
              <ol className="list-decimal pl-4 space-y-2 text-muted-foreground">
                <li>Clone the Figma Context MCP server: <code>git clone https://github.com/GLips/Figma-Context-MCP</code></li>
                <li>Follow its README to install dependencies and set your <b>FIGMA_PAT</b>.</li>
                <li>Start the MCP server with an HTTP/SSE gateway (see server docs). Note the gateway URL.</li>
                <li>Paste the gateway URL, token, and file URL above, then click Connect.</li>
              </ol>
              <a
                className="inline-flex items-center gap-2 text-primary hover:underline"
                href="https://github.com/GLips/Figma-Context-MCP"
                target="_blank"
                rel="noreferrer"
              >
                Open Figma-Context-MCP <ExternalLink className="h-4 w-4" />
              </a>
              <div className="flex items-center gap-2 text-emerald-300">
                <ShieldCheck className="h-4 w-4" /> Your configuration is stored locally only.
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}

function SearchIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <circle cx="11" cy="11" r="8"></circle>
      <path d="m21 21-4.3-4.3"></path>
    </svg>
  );
}