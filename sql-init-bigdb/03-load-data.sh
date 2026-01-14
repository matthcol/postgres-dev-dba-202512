#!/bin/bash
set -e

echo "========================================="
echo "Début du chargement des données TSV"
echo "========================================="

# Fonction pour charger un fichier TSV dans une table
load_tsv() {
    local table=$1
    local file=$2
    
    if [ -f "$file" ]; then
        echo "Chargement de $table depuis $file..."
        start_time=$(date +%s)
        
        # Utiliser COPY pour un chargement ultra-rapide
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
            \copy $table FROM '$file' WITH (FORMAT csv, DELIMITER E'\t', HEADER, ENCODING 'UTF-8', NULL '');
EOSQL
        
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        row_count=$(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM $table;")
        
        echo "✓ $table chargée : $row_count lignes en ${duration}s"
    else
        echo "⚠ Fichier non trouvé : $file"
    fi
}

# Désactiver temporairement les triggers et contraintes pour accélérer le chargement
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Désactiver l'autovacuum pendant le chargement
    ALTER SYSTEM SET autovacuum = off;
    SELECT pg_reload_conf();
EOSQL

# Charger toutes les tables depuis le répertoire /data
# Adapter ces lignes selon vos noms de tables et fichiers
# Exemple :
# load_tsv "clients" "/data/clients.tsv"
# load_tsv "commandes" "/data/commandes.tsv"
# load_tsv "produits" "/data/produits.tsv"

# Détection automatique des fichiers TSV
echo ""
echo "Chargement automatique des fichiers TSV..."
for tsv_file in ./data/*.tsv; do
    if [ -f "$tsv_file" ]; then
        # Extraire le nom de la table du nom de fichier (sans extension)
        table_name=$POSTGRES_SCHEMA.$(basename "$tsv_file" .tsv)
        load_tsv "$table_name" "$tsv_file"
    fi
done

# Réactiver l'autovacuum
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    ALTER SYSTEM SET autovacuum = on;
    SELECT pg_reload_conf();
EOSQL

echo ""
echo "========================================="
echo "Chargement des données terminé ✓"
echo "========================================="
