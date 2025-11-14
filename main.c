#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

char notes[100][256]; 
int notes_count = 0; 

void seisen_load_notes(const char *filepath)
{ 
    FILE *file = fopen(filepath, "r");

    if (!file)
    {
        printf("impossible d'ouvrir le fichier !");
        return;
    }
    char buffer[256];

    while (fgets(buffer, sizeof(buffer), file))
    {
        strcpy(notes[notes_count], buffer);
        notes_count++;
    }
    fclose(file);
}

const char *seisen_get_note(void)
{
    if(notes_count == 0)
    {
        return "Aucune note disponible";
    }
    int ligne = rand() % notes_count;
    return notes[ligne];

    
}

