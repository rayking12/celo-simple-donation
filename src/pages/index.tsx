import {
	useAccount,
	useConnect,
	useDisconnect,
	useBalance,
	useContractWrite,
	useContractRead,
	Address,
} from "wagmi";
import { InjectedConnector } from "wagmi/connectors/injected";
import { celoAlfajores } from "wagmi/chains";
import { DonationCard } from "@/components/card";
import { parseEther, formatEther } from "viem";
import ClientOnly from "@/client";
import { useState, useRef } from "react";
import donationAbi from "../contract/donation.abi.json";
import {
	Flex,
	Spacer,
	Button,
	Heading,
	Modal,
	ModalOverlay,
	ModalHeader,
	FormControl,
	FormLabel,
	ModalFooter,
	ModalBody,
	useToast,
	ModalCloseButton,
	Spinner,
	useDisclosure,
	ModalContent,
	Input,
	Box,
	Text,
	Card,
	CardBody,
} from "@chakra-ui/react";

const DONATION_CONTRACT_ADDRESS = "0x72458067342C7c87Ba4D93Dbc251C16d7A576C2c";

const NavBar = () => {
	const { address, isConnected } = useAccount();
	const toast = useToast();

	const { connect } = useConnect({
		connector: new InjectedConnector({
			chains: [celoAlfajores],
		}),
		chainId: celoAlfajores.id,
		onError(error) {
			toast({
				title: "Error",
				description:
					error.name === "ConnectorNotFoundError"
						? "Please install the CeloExtensionWallet."
						: error.message,
				position: "top-right",
				status: "error",
				duration: 3000,
				isClosable: true,
			});
		},
	});

	const { data: balance } = useBalance({
		address: address,
		watch: true,
	});

	const { disconnect } = useDisconnect();

	return (
		<Flex alignItems="center" p="4" boxShadow="md">
			<Heading as="h1" size="lg" fontWeight="bold">
				Donation Center
			</Heading>
			<Spacer />
			{isConnected ? (
				<Flex alignItems={"center"}>
					<Box>
						<Card mr={4} size={"sm"}>
							<CardBody>
								<Text fontWeight={600}>
									{balance && `${balance?.formatted} ${balance?.symbol}`}
								</Text>
							</CardBody>
						</Card>
					</Box>
					<Button colorScheme="blue" onClick={() => disconnect()}>
						Disconnect
					</Button>
				</Flex>
			) : (
				<Button colorScheme="blue" onClick={() => connect()}>
					Connect
				</Button>
			)}
		</Flex>
	);
};

const CreateCause = ({
	isOpen,
	onClose,
	createCause,
	isLoading,
}: {
	isOpen: boolean;
	onClose: () => void;
	createCause: (args: any) => void;
	isLoading: boolean;
}) => {
	const initialRef = useRef(null);
	const finalRef = useRef(null);
	const [values, setValues] = useState({
		name: "",
		goalAmount: "",
		description: "",
		imageUrl: "",
	});

	const { address } = useAccount();

	const handleInput = (field: keyof typeof values, value: string) => {
		setValues((prev) => ({ ...prev, [field]: value }));
	};
	const [file, setFile] = useState<any>(null);

	const retrieveFile = (e: any) => {
		const data = e.target.files[0];
		const reader = new window.FileReader();
		reader.readAsArrayBuffer(data);
		reader.onloadend = () => {
			setFile(Buffer.from(reader.result as ArrayBuffer));
		};

		e.preventDefault();
	};

	const handleSave = async () => {
		createCause({
			args: [
				values.name,
				address,
				values.description,
				parseEther(`${Number(values.goalAmount)}`),
				values.imageUrl,
			],
		});
	};

	return (
		<Modal
			initialFocusRef={initialRef}
			finalFocusRef={finalRef}
			isOpen={isOpen}
			onClose={onClose}
		>
			<ModalOverlay />
			<ModalContent>
				<ModalHeader>Create donation cause</ModalHeader>
				<ModalCloseButton />
				<ModalBody pb={6}>
					<FormControl>
						<FormLabel>Name</FormLabel>
						<Input
							ref={initialRef}
							placeholder="Name of cause"
							value={values.name}
							onChange={(event) => handleInput("name", event.target.value)}
						/>
					</FormControl>
					<FormControl my={8}>
						<FormLabel>Description</FormLabel>
						<Input
							placeholder="Description of cause"
							value={values.description}
							onChange={(event) =>
								handleInput("description", event.target.value)
							}
						/>
					</FormControl>
					<FormControl my={5}>
						<FormLabel>Upload image</FormLabel>

						<Input
							placeholder="Image Url"
							value={values.imageUrl}
							onChange={(event) => handleInput("imageUrl", event.target.value)}
						/>
					</FormControl>

					<FormControl mt={4}>
						<FormLabel>Goal Amount</FormLabel>
						<Input
							placeholder="e.g 1000.00"
							type="number"
							value={values.goalAmount}
							onChange={(event) =>
								handleInput("goalAmount", event.target.value)
							}
						/>
					</FormControl>
				</ModalBody>

				<ModalFooter>
					<Button
						colorScheme="blue"
						mr={3}
						isLoading={isLoading}
						isDisabled={
							!values.name || !values.goalAmount || !values.description
						}
						onClick={handleSave}
					>
						Save
					</Button>
					<Button onClick={onClose}>Cancel</Button>
				</ModalFooter>
			</ModalContent>
		</Modal>
	);
};
export default function Home() {
	const contractOpts = (fnName: string, args?: any) => {
		return {
			address: DONATION_CONTRACT_ADDRESS as Address,
			abi: donationAbi,
			functionName: fnName,
			watch: true,
			onError(error: any) {
				toast({
					title: "Error",
					description: error.message,
					position: "top-right",
					status: "error",
					duration: 3000,
					isClosable: true,
				});
			},
			args: args || [],
		};
	};

	const { data = [], isLoading: loadingAllCauses } = useContractRead(
		contractOpts("getAllCauses")
	);
	const { data: topDonors = [], isLoading: loadingTopDonors } = useContractRead(
		contractOpts("getOverallTopDonors")
	);

	const donationRequests: any = data;

	const donors: any = topDonors;

	const { isOpen, onOpen, onClose } = useDisclosure();

	const { write: createCause, isLoading } = useContractWrite({
		...contractOpts("createCause"),
		onSuccess() {
			onClose();
			toast({
				title: "Success",
				description: "Cause requested successfully",
				position: "top-right",
				status: "success",
				duration: 3000,
				isClosable: true,
			});
		},
	});

	const { address } = useAccount();

	const toast = useToast();

	return (
		<>
			<NavBar />
			<ClientOnly>
				<Flex flexDirection={{ base: "column", md: "row" }}>
					<Box width="60%" mx={{ sm: 2, md: 8 }}>
						<Flex alignItems={"center"} justifyContent={"space-between"} mt={4}>
							<Text fontSize="xl" fontWeight={700}>
								Campaigns
							</Text>
							<Button onClick={onOpen} variant={"outline"}>
								Request Donation
							</Button>
						</Flex>
						<Flex flexDirection={{ base: "column", md: "row" }}>
							{loadingAllCauses && (
								<Flex
									justifyContent={"center"}
									alignItems={"center"}
									width={"100vw"}
									height="400px"
								>
									<Spinner size="xl" />
								</Flex>
							)}
							{donationRequests &&
								!loadingAllCauses &&
								donationRequests.map((item: any, index: number) => (
									<DonationCard
										key={index}
										index={index + 1}
										title={item.name}
										description={item.description}
										address={address}
										contractOpts={contractOpts}
										loggedInAddress={item.beneficiary}
										withdrawalAmount={formatEther(item?.withdrawnAmount || 0)}
										closed={item?.closed}
										imageUrl={item.imageUrl}
										currentAmount={formatEther(item.currentAmount)}
										target={formatEther(item.goalAmount)}
									/>
								))}
						</Flex>
					</Box>
					<Box borderLeft={"1px solid #ededf2"} height="100vh" pl="4">
						<Text fontSize="xl" fontWeight={700} mt={4}>
							Leaderboards / Top Donors
						</Text>

						<Box mt={"4"}>
							{(!donors || !donors.length) && (
								<Box
									alignItems={"center"}
									justifyContent={"center"}
									width="100%"
								>
									<Text textAlign={"center"}>No current leader</Text>
								</Box>
							)}
							{donors &&
								donors.map(
									(donor: { donor: string; amount: bigint }, idx: number) => (
										<Box
											key={idx}
											mb={4}
											display={"flex"}
											justifyContent={"center"}
											alignItems={"center"}
										>
											<Text fontWeight={500}>{idx + 1}.</Text>
											<Box ml={5}>
												<Text fontWeight={700}>{donor.donor}</Text>
												<Text fontWeight={500} fontSize={14}>
													Total: {formatEther(donor.amount)}
												</Text>
											</Box>
										</Box>
									)
								)}
						</Box>
					</Box>
				</Flex>
			</ClientOnly>
			<CreateCause
				isOpen={isOpen}
				onClose={onClose}
				createCause={createCause}
				isLoading={isLoading}
			/>
		</>
	);
}
