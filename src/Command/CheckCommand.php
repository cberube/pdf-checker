<?php

namespace DigCon\PdfChecker\Command;


use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;
use Smalot\PdfParser\Parser;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;

class CheckCommand extends Command
{
    protected function configure()
    {
        $this->setName('check')
            ->addArgument('path', InputArgument::REQUIRED, 'Path to search')
            ->addOption('recursive', 'r', InputOption::VALUE_NONE, 'Recursively search directories')
            ->addOption('numAllowed', 'a', InputOption::VALUE_OPTIONAL, 'Number of allowed duplicate pages')
            ->setDescription('Check PDFs at path for duplicate pages');
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $parser = new Parser();

        $path = $input->getArgument('path');

        $fileList = array();
        if (!$input->getOption('recursive')) {
            foreach (glob($path . DIRECTORY_SEPARATOR . '*.pdf') as $filename) {
                $fileList[] = $filename;
            }
        } else {
            $directory = new RecursiveDirectoryIterator($path);
            foreach(new RecursiveIteratorIterator($directory) as $file)
            {
                if (substr($file->getFileName(), -4) === '.pdf') {
                    $fileList[] = $file->getPathName();
                }
            }
        }

        $firstFind = true;
        foreach ($fileList as $filePath) {
            if (!is_readable($filePath)) {
                $output->writeln('<warning>Unable to read file: ' . $filePath . '</warning>');
                continue;
            }

            $pdf = $parser->parseFile($filePath);
            $pages = $pdf->getPages();

            $checksums = [];
            foreach ($pages as $page) {
                $xobjects = $page->getXObjects();
                if (count($xobjects) > 0) {
                    $xobject = array_pop($xobjects);
                    $checksums[] = md5($xobject->getContent());
                }
            }

            if (count($checksums) !== count(array_unique($checksums))) {
                if ($firstFind) {
                    $firstFind = false;
                    $output->writeln('<error>Found duplicates!</error>');
                }
                $output->writeln($filePath);
            }
        }
    }
}