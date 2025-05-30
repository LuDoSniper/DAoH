<?php

namespace App\Controller;

use App\Entity\Node;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class NodeController extends AbstractController
{
    public function __construct(
        private readonly EntityManagerInterface $entityManager
    ){}

    #[Route('/api/admin/node/create', name: 'api_admin_node_create', methods: ['POST'])]
    public function create(
        Request $request
    ): JSONResponse
    {
        $data = json_decode($request->getContent(), true);
        $name = $data['name'];
        $address = $data['address'];

        if (empty($name) || empty($address)) {
            return new JsonResponse(['error' => 'Name or adresse missing or invalid'], Response::HTTP_BAD_REQUEST);
        }

        $nodes = $this->entityManager->getRepository(Node::class)->findAll();
        foreach ($nodes as $node) {
            if ($node->getName() === $name) {
                return new JsonResponse(['error' => 'Node name already exists'], Response::HTTP_BAD_REQUEST);
            }
        }

        $node = new Node();
        $node->setName($name);
        $node->setAddress($address);

        $this->entityManager->persist($node);
        $this->entityManager->flush();

        return new JsonResponse(['success' => 'Node created'], Response::HTTP_CREATED);
    }

    #[Route('/api/admin/node/delete/{id}', name: 'api_admin_node_delete', methods: ['POST'])]
    public function delete(
        Node $node
    ): JsonResponse
    {
        $this->entityManager->remove($node);
        $this->entityManager->flush();

        return new JsonResponse(['success' => 'Node deleted'], Response::HTTP_NO_CONTENT);
    }

    #[Route('/api/admin/node/update/{id}', name: 'api_admin_node_update', methods: ['POST'])]
    public function update(
        Request $request,
        Node $node
    ): JsonResponse
    {
        $data = json_decode($request->getContent(), true);
        $name = $data['name'];
        $address = $data['address'];

        if (empty($name) || empty($address)) {
            return new JsonResponse(['error' => 'Name or adresse missing or invalid'], Response::HTTP_BAD_REQUEST);
        }

        $node->setName($name);
        $node->setAddress($address);

        $this->entityManager->persist($node);
        $this->entityManager->flush();

        return new JsonResponse(['success' => 'Node updated'], Response::HTTP_NO_CONTENT);
    }

    #[Route('/api/node/list', name: 'api_node_list', methods: ['POST'])]
    public function list(): JsonResponse
    {
        $nodes = $this->entityManager->getRepository(Node::class)->findAll();

        $data = [];
        foreach ($nodes as $node) {
            $data[] = [
                'id' => $node->getId(),
                'name' => $node->getName(),
                'address' => $node->getAddress()
            ];
        }

        return new JsonResponse($data, Response::HTTP_OK);
    }
}