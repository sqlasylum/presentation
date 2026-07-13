import psycopg
import time
import random
import threading
import os
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5433'),
    'database': os.getenv('DB_NAME', 'bluebox'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', '')
}

# Load test profiles
PROFILES = {
    'default': {
        'name': 'Default Load Profile',
        'description': 'Balanced mix of read and write operations',
        'operations': ['insert', 'select', 'update', 'delete'],
        'weights': [2, 5, 2, 1],  # Favors reads over writes
        'table': 'load_test'
    }
    # Future profiles can be added here
    # Example:
    # 'read-heavy': {
    #     'name': 'Read-Heavy Profile',
    #     'description': 'Primarily SELECT operations for read testing',
    #     'operations': ['insert', 'select'],
    #     'weights': [1, 9],
    #     'table': 'load_test'
    # }
}

class LoadGenerator:
    def __init__(self, config, profile='default'):
        self.config = config
        self.profile_name = profile
        self.profile = PROFILES.get(profile, PROFILES['default'])
        self.stats = {
            'inserts': 0,
            'selects': 0,
            'updates': 0,
            'deletes': 0,
            'errors': 0
        }
        self.lock = threading.Lock()
        
    def get_connection(self):
        """Create a new database connection"""
        return psycopg.connect(
            host=self.config['host'],
            port=self.config['port'],
            dbname=self.config['database'],
            user=self.config['user'],
            password=self.config['password']
        )
    
    def initialize_table(self):
        """Create the test table if it doesn't exist"""
        conn = self.get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS load_test (
                        id SERIAL PRIMARY KEY,
                        name VARCHAR(100),
                        value INTEGER,
                        data TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cur.execute("""
                    CREATE INDEX IF NOT EXISTS idx_load_test_name 
                    ON load_test(name)
                """)
                cur.execute("""
                    CREATE INDEX IF NOT EXISTS idx_load_test_value 
                    ON load_test(value)
                """)
                conn.commit()
                print("✓ Test table 'load_test' initialized")
        except Exception as e:
            print(f"Error initializing table: {e}")
            conn.rollback()
        finally:
            conn.close()
    
    def perform_insert(self, conn):
        """Insert a random record"""
        try:
            with conn.cursor() as cur:
                name = f"test_{random.randint(1000, 9999)}"
                value = random.randint(1, 1000)
                data = f"Sample data {random.randint(1, 100000)}"
                
                cur.execute(
                    "INSERT INTO load_test (name, value, data) VALUES (%s, %s, %s)",
                    (name, value, data)
                )
                conn.commit()
                
            with self.lock:
                self.stats['inserts'] += 1
        except Exception as e:
            conn.rollback()
            with self.lock:
                self.stats['errors'] += 1
            print(f"Insert error: {e}")
    
    def perform_select(self, conn):
        """Perform a random SELECT query"""
        try:
            with conn.cursor() as cur:
                query_type = random.choice(['simple', 'aggregate', 'join'])
                
                if query_type == 'simple':
                    value = random.randint(1, 1000)
                    cur.execute(
                        "SELECT * FROM load_test WHERE value > %s LIMIT 10",
                        (value,)
                    )
                elif query_type == 'aggregate':
                    cur.execute(
                        "SELECT COUNT(*), AVG(value), MAX(value) FROM load_test"
                    )
                else:  # join simulation with self-join
                    cur.execute("""
                        SELECT a.id, a.name, b.value 
                        FROM load_test a 
                        JOIN load_test b ON a.value = b.value 
                        LIMIT 10
                    """)
                
                results = cur.fetchall()
                
            with self.lock:
                self.stats['selects'] += 1
        except Exception as e:
            with self.lock:
                self.stats['errors'] += 1
            print(f"Select error: {e}")
    
    def perform_update(self, conn):
        """Update a random record"""
        try:
            with conn.cursor() as cur:
                value = random.randint(1, 1000)
                new_value = random.randint(1, 1000)
                
                cur.execute(
                    """UPDATE load_test 
                       SET value = %s, updated_at = CURRENT_TIMESTAMP 
                       WHERE value = %s""",
                    (new_value, value)
                )
                conn.commit()
                
            with self.lock:
                self.stats['updates'] += 1
        except Exception as e:
            conn.rollback()
            with self.lock:
                self.stats['errors'] += 1
            print(f"Update error: {e}")
    
    def perform_delete(self, conn):
        """Delete old records"""
        try:
            with conn.cursor() as cur:
                # Only delete if we have enough records
                cur.execute("SELECT COUNT(*) FROM load_test")
                count = cur.fetchone()[0]
                
                if count > 1000:
                    cur.execute(
                        """DELETE FROM load_test 
                           WHERE id IN (
                               SELECT id FROM load_test 
                               ORDER BY created_at 
                               LIMIT 100
                           )"""
                    )
                    conn.commit()
                    
            with self.lock:
                self.stats['deletes'] += 1
        except Exception as e:
            conn.rollback()
            with self.lock:
                self.stats['errors'] += 1
            print(f"Delete error: {e}")
    
    def worker(self, duration, operations_per_second):
        """Worker thread that generates load"""
        conn = self.get_connection()
        end_time = time.time() + duration
        delay = 1.0 / operations_per_second if operations_per_second > 0 else 0
        
        try:
            while time.time() < end_time:
                # Choose an operation based on the profile's configuration
                operation = random.choices(
                    self.profile['operations'],
                    weights=self.profile['weights']
                )[0]
                
                if operation == 'insert':
                    self.perform_insert(conn)
                elif operation == 'select':
                    self.perform_select(conn)
                elif operation == 'update':
                    self.perform_update(conn)
                elif operation == 'delete':
                    self.perform_delete(conn)
                
                if delay > 0:
                    time.sleep(delay)
        finally:
            conn.close()
    
    def run(self, duration=60, num_threads=5, ops_per_second=10):
        """Run the load test"""
        print(f"\n{'='*60}")
        print(f"Starting Load Test")
        print(f"{'='*60}")
        print(f"Profile: {self.profile['name']}")
        print(f"Description: {self.profile['description']}")
        print(f"Duration: {duration} seconds")
        print(f"Threads: {num_threads}")
        print(f"Target ops/sec per thread: {ops_per_second}")
        print(f"Database: {self.config['database']} at {self.config['host']}:{self.config['port']}")
        print(f"{'='*60}\n")
        
        # Initialize table
        self.initialize_table()
        
        # Start worker threads
        threads = []
        start_time = time.time()
        
        for i in range(num_threads):
            thread = threading.Thread(
                target=self.worker,
                args=(duration, ops_per_second)
            )
            thread.start()
            threads.append(thread)
        
        # Monitor progress
        while any(t.is_alive() for t in threads):
            time.sleep(5)
            elapsed = time.time() - start_time
            with self.lock:
                total_ops = sum([
                    self.stats['inserts'],
                    self.stats['selects'],
                    self.stats['updates'],
                    self.stats['deletes']
                ])
                ops_per_sec = total_ops / elapsed if elapsed > 0 else 0
                print(f"[{elapsed:.1f}s] Operations: {total_ops} ({ops_per_sec:.1f} ops/sec)")
        
        # Wait for all threads to complete
        for thread in threads:
            thread.join()
        
        # Print final statistics
        elapsed = time.time() - start_time
        total_ops = sum([
            self.stats['inserts'],
            self.stats['selects'],
            self.stats['updates'],
            self.stats['deletes']
        ])
        
        print(f"\n{'='*60}")
        print(f"Load Test Complete")
        print(f"{'='*60}")
        print(f"Duration: {elapsed:.2f} seconds")
        print(f"Total Operations: {total_ops}")
        print(f"Average ops/sec: {total_ops / elapsed:.2f}")
        print(f"\nBreakdown:")
        print(f"  Inserts: {self.stats['inserts']}")
        print(f"  Selects: {self.stats['selects']}")
        print(f"  Updates: {self.stats['updates']}")
        print(f"  Deletes: {self.stats['deletes']}")
        print(f"  Errors: {self.stats['errors']}")
        print(f"{'='*60}\n")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='PostgreSQL Load Generator')
    parser.add_argument('--duration', type=int, default=60,
                        help='Duration in seconds (default: 60)')
    parser.add_argument('--threads', type=int, default=5,
                        help='Number of concurrent threads (default: 5)')
    parser.add_argument('--ops-per-second', type=int, default=10,
                        help='Target operations per second per thread (default: 10)')
    parser.add_argument('--profile', type=str, default='default',
                        choices=list(PROFILES.keys()),
                        help=f'Load test profile (default: default). Available: {", ".join(PROFILES.keys())}')
    parser.add_argument('--list-profiles', action='store_true',
                        help='List all available profiles and exit')
    
    args = parser.parse_args()
    
    # List profiles if requested
    if args.list_profiles:
        print("\nAvailable Load Test Profiles:")
        print("=" * 60)
        for profile_key, profile in PROFILES.items():
            print(f"\n{profile_key}:")
            print(f"  Name: {profile['name']}")
            print(f"  Description: {profile['description']}")
            print(f"  Operations: {', '.join(profile['operations'])}")
            print(f"  Weights: {profile['weights']}")
        print("\n")
        return
    
    try:
        generator = LoadGenerator(DB_CONFIG, profile=args.profile)
        generator.run(
            duration=args.duration,
            num_threads=args.threads,
            ops_per_second=args.ops_per_second
        )
    except Exception as e:
        print(f"Error: {e}")
        print("\nMake sure:")
        print("1. PostgreSQL is running")
        print("2. Database 'bluebox' exists")
        print("3. Connection credentials are correct in .env file")


if __name__ == '__main__':
    main()
