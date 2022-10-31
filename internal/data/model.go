package data

import (
	"database/sql"
	"errors"
)

// Define a custom ErrRecordNotFound error. We'll return this from our Get() method
// looking up a movie that doesn't exist in our database.
var (
	ErrRecordNotFound = errors.New("record not found")
	ErrEditConflict   = errors.New("edit conflict")
)

// Create a models struct which wraps the MovieModel.
type Models struct {
	Movie       MovieModel
	Users       UserModel
	Token       TokenModel
	Permissions PermissionModel
}

// For ease of use, we also add a New() method which returns a Models struct containing
// the initialized MovieModel.
func NewModels(db *sql.DB) Models {
	return Models{
		Movie:       MovieModel{DB: db},
		Permissions: PermissionModel{DB: db},
		Token:       TokenModel{DB: db},
		Users:       UserModel{DB: db},
	}
}
