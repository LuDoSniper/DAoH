<?php

namespace App\Command;

use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'app:user:role',
    description: 'Add a short description for your command',
)]
class UserRoleCommand extends Command
{
    public function __construct(
        public EntityManagerInterface $entityManager
    )
    {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->addArgument('user_id', InputArgument::REQUIRED, 'Id of the user')
            ->addOption('operation', null, InputOption::VALUE_REQUIRED, 'The operation to do on the user')
            ->addOption('value', null, InputOption::VALUE_OPTIONAL, 'The value to operate on the user')
        ;
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $user_id = $input->getArgument('user_id');
        $operation = $input->getOption('operation');
        $value = $input->getOption('value');

        if ($value || $operation === 'list'){
            switch ($operation){
                case 'add':
                    $user = $this->add($user_id, $value);
                    $message = 'update';
                    break;
                case 'remove':
                    $user = $this->remove($user_id, $value);
                    $message = 'update';
                    break;
                case 'list':
                    $roles = $this->list($user_id);
                    $this->display_roles($io, $roles);
                    $message = 'listing';
                    break;
                default:
                    $io->error('Unkown value of argument operation ('.$operation.')');
                    return Command::INVALID;
            }
            if (isset($user)){
                $this->entityManager->persist($user);
                $this->entityManager->flush();
            }
            $io->success('The '.$message.' is successful');
            return Command::SUCCESS;
        } else {
            $io->error('Missing value');
            return Command::INVALID;
        }
    }

    private function list(int $user_id): array
    {
        $user = $this->entityManager->getRepository(User::class)->findOneBy(['id' => $user_id]);
        return $user->getRoles();
    }

    private function add(int $user_id, string $value): User
    {
        $user = $this->entityManager->getRepository(User::class)->findOneBy(['id' => $user_id]);
        $user->addRole($value);

        return $user;
    }

    private function remove(int $user_id, string $values): User
    {
        $user = $this->entityManager->getRepository(User::class)->findOneBy(['id' => $user_id]);
        $user->removeRole($values);

        return $user;
    }

    private function display_roles(SymfonyStyle $io, array $roles): void
    {
        $io->listing($roles);
    }
}