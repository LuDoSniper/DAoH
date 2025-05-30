<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\DependencyInjection\ParameterBag\ParameterBagInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

class NodeController extends AbstractController
{
    public function __construct(
        private readonly ParameterBagInterface $params,
    ){}

    #[Route('/api/get', name: 'api_get', methods: ['POST'])]
    public function get(): JsonResponse
    {
        $data = [
            'port' => $this->params->get('node_port')
        ];

        return new JsonResponse($data);
    }
}