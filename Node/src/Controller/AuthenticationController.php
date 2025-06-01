<?php

namespace App\Controller;

use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\Routing\Attribute\Route;

class AuthenticationController extends AbstractController
{
    public function __construct(
        private readonly EntityManagerInterface $entityManager,
        private readonly UserPasswordHasherInterface $hasher
    ){}

    #[Route('/register', name: 'app_register', methods: ['POST'])]
    public function register(
        Request $request
    ): JsonResponse
    {
        $data = json_decode($request->getContent(), true);
        $username = $data['username'];
        $password = $data['password'];

        if (!$username || !$password) {
            return $this->json(['error' => 'Nom d\'utilisateur et mot de passe requis'], Response::HTTP_BAD_REQUEST);
        }

        $users = $this->entityManager->getRepository(User::class)->findAll();
        foreach ($users as $var_user) {
            if ($var_user->getUsername() === $username) {
                return new JsonResponse(['message' => 'Username already exists'], Response::HTTP_BAD_REQUEST);
            }
        }

        $user = new User();
        $user->setUsername($username);

        $user->setPassword($this->hasher->hashPassword($user, $password));

        $this->entityManager->persist($user);
        $this->entityManager->flush();

        return $this->json(['success' => true], Response::HTTP_CREATED);
    }
}