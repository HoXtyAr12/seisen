#ifndef SEISEN_H
#define SEISEN_H

// Chargement des notes depuis un fichier texte
void seisen_load_notes(const char *filepath);

// Récupération d'une note aléatoire
const char *seisen_get_note(void);

// Libération des ressources (actuellement vide, mais utile si malloc plus tard)
void seisen_cleanup(void);

#endif // SEISEN_H

