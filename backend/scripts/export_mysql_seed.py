#!/usr/bin/env python3
from __future__ import annotations

import re
import shutil
import sqlite3
import subprocess
import tempfile
import os
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BACKEND_DIR = ROOT / "backend"
MIGRATE_PATH = BACKEND_DIR / "scripts" / "migrate.php"
OUTPUT_PATH = BACKEND_DIR / "database" / "halloparty_mysql.sql"


ALTER_STATEMENTS = [
    "ALTER TABLE users ADD COLUMN agency_id INT UNSIGNED NULL;",
    "ALTER TABLE users ADD COLUMN agency_role VARCHAR(30) NULL;",
    "ALTER TABLE users ADD COLUMN agency_joined_at DATETIME NULL;",
    "ALTER TABLE users ADD COLUMN google_sub VARCHAR(191) NULL;",
    "ALTER TABLE users ADD COLUMN auth_provider VARCHAR(30) NULL;",
    "CREATE UNIQUE INDEX uq_users_google_sub ON users (google_sub);",
    "ALTER TABLE users ADD COLUMN avatar_asset VARCHAR(255) NULL DEFAULT 'assets/images/profile_avatar.png';",
    "ALTER TABLE users ADD COLUMN profile_handle VARCHAR(120) NULL DEFAULT 'Shark.island';",
    "ALTER TABLE users ADD COLUMN signature_text VARCHAR(255) NULL DEFAULT 'ليس لديك المقدمة الشخصية';",
    "ALTER TABLE users ADD COLUMN following_count INT NOT NULL DEFAULT 50;",
    "ALTER TABLE users ADD COLUMN followers_count INT NOT NULL DEFAULT 100;",
    "ALTER TABLE users ADD COLUMN friends_count INT NOT NULL DEFAULT 123;",
    "ALTER TABLE users ADD COLUMN level_current INT NOT NULL DEFAULT 0;",
    "ALTER TABLE users ADD COLUMN level_next INT NOT NULL DEFAULT 1;",
    "ALTER TABLE users ADD COLUMN level_progress_percent INT NOT NULL DEFAULT 67;",
    "ALTER TABLE users ADD COLUMN vip_tier VARCHAR(40) NULL DEFAULT 'VIP 0';",
    "ALTER TABLE users ADD COLUMN svip_tier VARCHAR(40) NULL DEFAULT 'SVIP 0';",
    "ALTER TABLE users ADD COLUMN badges_count INT NOT NULL DEFAULT 4;",
    "ALTER TABLE users ADD COLUMN tasks_completed INT NOT NULL DEFAULT 5;",
    "ALTER TABLE users ADD COLUMN tasks_total INT NOT NULL DEFAULT 12;",
]


def sql_literal(value: object) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bytes):
        return "X'" + value.hex() + "'"
    if isinstance(value, (int, float)):
        return str(value)
    text = str(value).replace("\\", "\\\\").replace("'", "''")
    return f"'{text}'"


def extract_mysql_create_statements() -> list[str]:
    source = MIGRATE_PATH.read_text(encoding="utf-8")
    matches = re.findall(
        r"'(CREATE TABLE IF NOT EXISTS [^']*?ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci)'",
        source,
        flags=re.S,
    )

    statements: list[str] = []
    seen: set[str] = set()
    for match in matches:
        statement = match.strip()
        if statement in seen:
            continue
        seen.add(statement)
        statements.append(statement + ";")
    return statements


def table_name_from_create(statement: str) -> str:
    match = re.search(r"CREATE TABLE IF NOT EXISTS\s+([a-zA-Z0-9_]+)\s*\(", statement)
    if not match:
        raise RuntimeError(f"Unable to detect table name in statement: {statement[:80]}")
    return match.group(1)


def build_clean_sqlite_database() -> Path:
    temp_dir = Path(tempfile.mkdtemp(prefix="halloparty_export_"))
    temp_backend = temp_dir / "backend"
    shutil.copytree(BACKEND_DIR, temp_backend)

    sqlite_path = temp_backend / "database" / "dev.sqlite"
    if sqlite_path.exists():
        sqlite_path.unlink()

    subprocess.run(
        ["php", "scripts/migrate.php"],
        cwd=temp_backend,
        env={**os.environ, "APP_DB_DRIVER": "sqlite"},
        check=True,
    )
    return sqlite_path


def export_inserts(sqlite_path: Path, table_order: list[str]) -> list[str]:
    connection = sqlite3.connect(str(sqlite_path))
    connection.row_factory = sqlite3.Row
    cursor = connection.cursor()

    lines: list[str] = []
    for table in table_order:
        rows = cursor.execute(f"SELECT * FROM {table}").fetchall()
        if not rows:
            continue

        columns = [column["name"] for column in cursor.execute(f"PRAGMA table_info({table})").fetchall()]
        column_sql = ", ".join(f"`{column}`" for column in columns)
        values_sql = []
        for row in rows:
            values_sql.append("(" + ", ".join(sql_literal(row[column]) for column in columns) + ")")

        lines.append(f"-- Data for table `{table}`")
        lines.append(f"INSERT INTO `{table}` ({column_sql}) VALUES")
        lines.append(",\n".join(values_sql) + ";")
        lines.append("")

    connection.close()
    return lines


def main() -> None:
    create_statements = extract_mysql_create_statements()
    table_order = [table_name_from_create(statement) for statement in create_statements]
    sqlite_path = build_clean_sqlite_database()
    insert_statements = export_inserts(sqlite_path, table_order)

    lines = [
        "-- HalloParty bootstrap SQL for MySQL 8+",
        "-- Import this file into an empty utf8mb4 database from aaPanel/phpMyAdmin.",
        "SET NAMES utf8mb4;",
        "SET time_zone = '+00:00';",
        "SET FOREIGN_KEY_CHECKS = 0;",
        "SET UNIQUE_CHECKS = 0;",
        "",
        "-- Schema",
    ]
    lines.extend(create_statements)
    lines.append("")
    lines.append("-- Post-create user columns")
    lines.extend(ALTER_STATEMENTS)
    lines.append("")
    lines.append("-- Seed data")
    lines.extend(insert_statements)
    lines.extend(
        [
            "SET UNIQUE_CHECKS = 1;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
        ]
    )

    OUTPUT_PATH.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
