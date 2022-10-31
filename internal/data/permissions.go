package data

import (
	"context"
	"database/sql"
	"github.com/lib/pq"
	"time"
)

type Permissions []string

// Add a helper method to check whether the Permissions slice contains a specific
// permission code.

func (p Permissions) Include(code string) bool {
	for i := range p {
		if code == p[i] {
			return true
		}
	}

	return false
}

type PermissionModel struct {
	DB *sql.DB
}

// The GetAllForUser() method returns all permission codes for a specific user in a
// Permissions slice. The code in this method should feel very familiar --- it uses the // standard pattern that we've already seen before for retrieving multiple data rows in
// an SQL query.

func (m PermissionModel) GetAllForUser(userID int64) (Permissions, error) {
	query := `
		SELECT p.code
		FROM permissions p
		INNER JOIN user_permissions up ON up.permission_id = p.id
		INNER JOIN users u ON up.user_id = u.id
		WHERE u.id = $1 
	`
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := m.DB.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}

	defer rows.Close()

	var permissions Permissions

	for rows.Next() {
		var permission string

		err := rows.Scan(&permission)

		if err != nil {
			return nil, err
		}

		permissions = append(permissions, permission)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return permissions, nil
}

func (m PermissionModel) AddForUser(userID int64, codes ...string) error {
	query := `
		INSERT INTO user_permissions
		SELECT $1, permissions.id FROM permissions.code = ANY($2)
	`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	_, err := m.DB.ExecContext(ctx, query, userID, pq.Array(codes))
	return err
}
