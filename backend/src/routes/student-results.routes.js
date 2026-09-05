const { Router } = require('express');
const resultController = require('../controllers/result.controller');

// Mounted at /students in routes/index.js, BEFORE the general
// authenticate+authorize(INSTITUTE_ADMIN)-only /students gate, with its
// own authenticate+authorize(INSTITUTE_ADMIN, TEACHER) - a Teacher needs
// to see their own students' results without getting full student
// management access. Any request that doesn't match a route here
// (e.g. POST /students to create a student) falls through to the
// general /students routes and their stricter gate, unaffected.
const router = Router();

router.get('/:studentId/results', resultController.getStudentResults);
router.get('/:studentId/results/:resultId', resultController.getStudentResultById);

module.exports = router;
