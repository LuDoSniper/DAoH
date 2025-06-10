<?php

namespace App\Controller;

use App\Entity\Character;
use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\DependencyInjection\ParameterBag\ParameterBagInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class CharacterController extends AbstractController
{
    public function __construct(
        private readonly EntityManagerInterface $entityManager,
        private readonly ParameterBagInterface $params
    ){}

    #[Route('/api/character/create', name: 'api_character_create', methods: ['POST'])]
    public function create(
        Request $request
    ): JSONResponse
    {
        $user = $this->getUser();
        if (!($user instanceof User)) {
            return new JsonResponse(['message' => 'An error occurred while getting user informations'], Response::HTTP_UNAUTHORIZED);
        }

        if ($user->getCharacters()->count() >= $this->params->get('max_character_count')) {
            return new JsonResponse(['message' => 'Characters limit reached'], Response::HTTP_BAD_REQUEST);
        }

        $data = json_decode($request->getContent(), true);
        if (!isset($data['name']) || !isset($data['saved_data'])) {
            return new JsonResponse(['message' => 'Name and saved_data cannot be empty'], Response::HTTP_BAD_REQUEST);
        }

        $name = $data['name'];
        $saved_data = $data['saved_data'];

        $characters = $this->entityManager->getRepository(Character::class)->findAll();
        foreach ($characters as $character) {
            if ($character->getName() === $name) {
                return new JsonResponse(['message' => 'Character name already exists'], Response::HTTP_BAD_REQUEST);
            }
        }

        $character = new Character();
        $character->setUser($user);
        $character->setName($name);
        $character->setSavedData($saved_data);

        $user->addCharacter($character);

        $this->entityManager->persist($character);
        $this->entityManager->flush();

        return new JsonResponse(['message' => 'Character created'], Response::HTTP_CREATED);
    }

    #[Route('/api/character/update/{id}', name: 'api_character_update', methods: ['POST'])]
    public function update(
        Request $request,
        Character $character
    ): JSONResponse
    {
        $data = json_decode($request->getContent(), true);
        if ((isset($data['name']) && empty($data['name'])) && (isset($data['saved_data']) && empty($data['saved_data']))) {
            return new JsonResponse(['message' => 'Name and saved_data cannot be empty'], Response::HTTP_BAD_REQUEST);
        }

        if (isset($data['name'])) {
            $name = $data['name'];

            $characters = $this->entityManager->getRepository(Character::class)->findAll();
            foreach ($characters as $var_character) {
                if ($var_character->getName() === $name) {
                    return new JsonResponse(['message' => 'Character name already exists'], Response::HTTP_BAD_REQUEST);
                }
            }

            $character->setName($name);
        }
        if (isset($data['saved_data'])) {
            $character->setSavedData($data['saved_data']);
        }

        $this->entityManager->flush();

        return new JsonResponse(['message' => 'Character updated'], Response::HTTP_OK);
    }

    #[Route('/api/character/remove/{id}', name: 'api_character_remove', methods: ['POST'])]
    public function remove(
        Character $character
    ): JSONResponse
    {
        $user = $this->getUser();
        if (!($user instanceof User)) {
            return new JsonResponse(['message' => 'An error occurred while getting user informations'], Response::HTTP_UNAUTHORIZED);
        }

        $user->removeCharacter($character);

        $this->entityManager->remove($character);
        $this->entityManager->flush();

        return new JsonResponse(['message' => 'Character removed'], Response::HTTP_OK);
    }

    #[Route('/api/character/list', name: 'api_character_list', methods: ['POST'])]
    public function list(): JSONResponse
    {
        $user = $this->getUser();
        if (!($user instanceof User)) {
            return new JsonResponse(['message' => 'An error occurred while getting user informations'], Response::HTTP_UNAUTHORIZED);
        }

        $data = [
            "owner_id" => $user->getId(),
            "characters" => []
        ];
        foreach ($user->getCharacters() as $character) {
            $data["characters"][] = [
                'id' => $character->getId(),
                'name' => $character->getName(),
                'saved_data' => $character->getSavedData(),
            ];
        }

        return new JsonResponse($data, Response::HTTP_OK);
    }
}