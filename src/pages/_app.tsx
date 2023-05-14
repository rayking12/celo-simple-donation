import "@/styles/globals.css";
import { ChakraProvider } from "@chakra-ui/react";
import { WagmiConfig, createConfig } from "wagmi";
import { createPublicClient, http } from "viem";
import { celoAlfajores } from "wagmi/chains";
import type { AppProps } from "next/app";

const config = createConfig({
	autoConnect: true,
	publicClient: createPublicClient({
		chain: celoAlfajores,
		transport: http(),
	}),
});

export default function App({ Component, pageProps }: AppProps) {
	return (
		<ChakraProvider>
			<WagmiConfig config={config}>
				<Component {...pageProps} />
			</WagmiConfig>
		</ChakraProvider>
	);
}
