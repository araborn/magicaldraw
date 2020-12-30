var	gulp = require('gulp'),
	exist = require('gulp-exist'),
	watch = require('gulp-watch'),
	newer = require('gulp-newer'),
	zip = require('gulp-zip'),
	plumber = require('gulp-plumber'),
	rename = require('gulp-rename');
	
var secrets = require('./exist-secrets.json')

var sourceDir = 'app/'

var buildDest = 'build/';


var localExist = exist.createClient({
		host: "localhost",
		port: 8080,
		path: "/exist/xmlrpc",
		basic_auth: secrets.local
	});

var remoteExist = exist.createClient({
		host: "projects.uni-koeln.de",
		port: 8080,
		path: "/xmlrpc",
		basic_auth: secrets.remote
});

var permissions = { 'controller.xql': 'rwxr-xr-x' };


// ------ Copy (and compile) sources and assets to build dir ----------



gulp.task('copy', function() {
	return gulp.src(sourceDir + '**/*')
		   	.pipe(newer(buildDest))
		   	.pipe(gulp.dest(buildDest))
})


gulp.task('build', ['copy']);




// ------ Deploy build dir to eXist ----------


gulp.task('local-upload', ['build'], function() {
	return gulp.src(buildDest + '**/*', {base: buildDest})
		.pipe(localExist.newer({target: "/db/apps/magicaldraw/"}))
		.pipe(localExist.dest({
			target: "/db/apps/magicaldraw",
			permissions: permissions
		}));
});
gulp.task('deploy-local',['local-upload']);



gulp.task('remote-upload', ['build'], function() {

	return gulp.src(buildDest + '**/*', {base: buildDest})
		.pipe(exist.newer(exist_remote_conf))
		.pipe(exist.dest(exist_remote_conf));
});

gulp.task('remote-post-install', ['remote-upload'], function() {
	return gulp.src('scripts/post-deploy.xql')
		.pipe(exist.query(exist_remote_conf));
});

gulp.task('deploy-remote', ['remote-upload', 'remote-post-install']);





// ------ Make eXist XAR Package ----------


gulp.task('xar', ['build'], function() {
	var p = require('./package.json');

	return gulp.src(buildDest + '**/*', {base: buildDest})
			.pipe(zip("magicaldraw-" + p.version + ".xar"))
			.pipe(gulp.dest("."));
});



// ------ WATCH ----------


gulp.task('watch-main', function() {
	return watch(buildDest, {
			ignoreInitial: true,
			base: buildDest,
			name: 'Main Watcher'
	})
	.pipe(plumber())
	.pipe(exist.dest(exist_local_conf))
});



gulp.task('watch-copy', function() {
	gulp.watch([sourceDir + '**/*'], ['copy']);
});



gulp.task('watch', ['watch-copy', 'watch-main']);
