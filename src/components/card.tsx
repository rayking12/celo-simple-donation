import {
	Heading,
	Text,
	Badge,
	Box,
	useColorModeValue,
	Center,
	Modal,
	ModalOverlay,
	ModalHeader,
	FormControl,
	ModalCloseButton,
	useToast,
	useDisclosure,
	FormLabel,
	ModalContent,
	Input,
	Progress,
	ModalFooter,
	ModalBody,
	Button,
	Flex,
	Image,
	Stack,
} from "@chakra-ui/react";
import { useContractWrite } from "wagmi";

import { useState } from "react";
import { parseEther } from "viem";

interface IDonate {
	imageUrl: string;
	title: string;
	description: string;
	currentAmount: string;
	target: string;
	closed?: boolean;
	address?: `0x${string}`;
	contractOpts: any;
	index: number;
	withdrawalAmount: string;
	loggedInAddress: `0x${string}`;
}

export const DonationCard = ({
	imageUrl,
	title,
	description,
	currentAmount,
	target,
	closed,
	loggedInAddress,
	withdrawalAmount,
	contractOpts,
	index,
	address,
}: IDonate) => {
	const [donationAmount, setDonationAmount] = useState("");
	const getPercentage = () => {
		return (Number(currentAmount) * 100) / Number(target);
	};

	const isOwner = loggedInAddress === address;

	const { isOpen, onOpen, onClose } = useDisclosure();

	const toast = useToast();

	const { write: donate, isLoading: donationLoader } = useContractWrite({
		...contractOpts("donate"),
		onSuccess() {
			onClose();
			toast({
				title: "Success",
				description: "Donation  successful",
				position: "top-right",
				status: "success",
				duration: 3000,
				isClosable: true,
			});
		},
	});

	const { write: requestDonation, isLoading: donationRequestLoader } =
		useContractWrite({
			...contractOpts("requestDonation"),
			onSuccess() {
				toast({
					title: "Success",
					description: "Donation withdrawal  successful",
					position: "top-right",
					status: "success",
					duration: 3000,
					isClosable: true,
				});
			},
		});

	const { write: closeCause, isLoading: closeLoader } = useContractWrite({
		...contractOpts("closeCause"),
		onSuccess() {
			toast({
				title: "Success",
				description: "Donation closed successful",
				position: "top-right",
				status: "success",
				duration: 3000,
				isClosable: true,
			});
		},
	});

	return (
		<Center py={6} ml={4}>
			<Stack
				borderWidth="1px"
				borderRadius="lg"
				w={{ sm: "100%", md: "300px" }}
				height={{ sm: "476px", md: "100%" }}
				bg={useColorModeValue("white", "gray.900")}
				padding={4}
			>
				<Flex flex={1} bg="blue.200">
					<Image
						objectFit="contain"
						boxSize="100%"
						height="200px"
						src={imageUrl}
						alt="donation url"
					/>
				</Flex>
				<Stack flex={1} flexDirection="column" p={1} pt={2}>
					<Flex>
						{closed && (
							<Badge colorScheme="red" width={"58px"} mr={"3"}>
								Closed
							</Badge>
						)}

						{isOwner && (
							<Badge colorScheme="green" width={"58px"} mr={"3"}>
								Owner
							</Badge>
						)}
					</Flex>
					<Heading fontSize={"2xl"} fontWeight={700} fontFamily={"body"}>
						{title}
					</Heading>

					<Text color={useColorModeValue("gray.700", "gray.400")}>
						{description}
					</Text>
					<Stack
						direction={"row"}
						mt={6}
						display={"flex"}
						alignItems={"center"}
						justifyContent={"space-between"}
					>
						<Badge
							px={2}
							py={1}
							bg={useColorModeValue("gray.50", "gray.800")}
							fontWeight={"400"}
						>
							Target:
						</Badge>
						<Box
							fontSize="lg"
							fontWeight={600}
							color={useColorModeValue("gray.800", "white")}
						>
							{target}
						</Box>
					</Stack>
					<Stack
						direction={"row"}
						mt={6}
						display={"flex"}
						alignItems={"center"}
						justifyContent={"space-between"}
					>
						<Badge
							px={2}
							py={1}
							bg={useColorModeValue("gray.50", "gray.800")}
							fontWeight={"400"}
						>
							Current Raise:
						</Badge>
						<Box
							fontSize="lg"
							fontWeight={600}
							color={useColorModeValue("gray.800", "white")}
						>
							{currentAmount}
						</Box>
					</Stack>
					{isOwner && (
						<Stack
							direction={"row"}
							mt={6}
							display={"flex"}
							alignItems={"center"}
							justifyContent={"space-between"}
						>
							<Badge px={2} py={1} bg={"gray.50"} fontWeight={"400"}>
								Withdrawable Amount:
							</Badge>
							<Box fontSize="lg" fontWeight={600} color={"gray.800"}>
								{Number(currentAmount) - Number(withdrawalAmount)}
							</Box>
						</Stack>
					)}
					<Progress value={getPercentage()} size="sm" colorScheme="pink" />
					<Stack
						width={"100%"}
						mt={"2rem"}
						direction={"row"}
						padding={2}
						justifyContent={"space-between"}
						alignItems={"center"}
					>
						<Button
							flex={1}
							fontSize={"sm"}
							onClick={onOpen}
							isDisabled={closed}
							rounded={"full"}
							_focus={{
								bg: "gray.200",
							}}
						>
							Donate
						</Button>
						{isOwner && !closed && (
							<Button
								flex={1}
								fontSize={"sm"}
								rounded={"full"}
								bg={"blue.400"}
								px={"4"}
								color={"white"}
								isLoading={closeLoader}
								onClick={() => {
									closeCause({
										args: [index],
									});
								}}
								boxShadow={
									"0px 1px 25px -5px rgb(66 153 225 / 48%), 0 10px 10px -5px rgb(66 153 225 / 43%)"
								}
								_hover={{
									bg: "blue.500",
								}}
								_focus={{
									bg: "blue.500",
								}}
							>
								Close Donation
							</Button>
						)}
					</Stack>
					{isOwner && (
						<Button
							fontSize={"sm"}
							onClick={() => {
								requestDonation({
									args: [index, parseEther(`${Number(currentAmount)}`)],
								});
							}}
							py="6"
							isLoading={donationRequestLoader}
							isDisabled={Number(currentAmount) - Number(withdrawalAmount) <= 0}
							rounded={"full"}
							_focus={{
								bg: "gray.200",
							}}
						>
							Withdraw
						</Button>
					)}
				</Stack>
			</Stack>
			<Modal isOpen={isOpen} onClose={onClose}>
				<ModalOverlay />
				<ModalContent>
					<ModalHeader>Create donation cause</ModalHeader>
					<ModalCloseButton />
					<ModalBody pb={6}>
						<FormControl>
							<FormLabel>Amount to donate</FormLabel>
							<Input
								placeholder="e.g 1000.00"
								type="number"
								value={donationAmount}
								onChange={(event) => setDonationAmount(event.target.value)}
							/>
						</FormControl>
					</ModalBody>

					<ModalFooter>
						<Button
							colorScheme="blue"
							mr={3}
							isLoading={donationLoader}
							isDisabled={!donationAmount}
							onClick={() =>
								donate({
									value: parseEther(`${Number(donationAmount)}`),
									args: [index],
								})
							}
						>
							Donate
						</Button>
						<Button onClick={onClose}>Cancel</Button>
					</ModalFooter>
				</ModalContent>
			</Modal>
		</Center>
	);
};
