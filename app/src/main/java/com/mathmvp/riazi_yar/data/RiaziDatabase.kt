package com.mathmvp.riazi_yar.data

import androidx.room.*
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.flow.Flow

@Entity(tableName = "skill_mastery")
data class SkillMasteryEntity(
    @PrimaryKey val skillId: String,
    val lessonId: String,
    val masteryScore: Float = 0.0f,
    val attemptsCount: Int = 0,
    val correctCount: Int = 0,
    val wrongCount: Int = 0,
    val totalResponseTimeMs: Long = 0L,
    val hintsUsedTotal: Int = 0,
    val consecutiveErrors: Int = 0,
    val repetitionCount: Int = 0,
    val easeFactor: Float = 2.5f,
    val reviewIntervalDays: Int = 1,
    val nextReviewEpochMs: Long = 0L,
    val lastMisconceptionCode: String? = null,
    val difficultyLevel: String = "EASY",
    val remedialRecommended: Boolean = false,
    val updatedAtEpochMs: Long = System.currentTimeMillis()
)

@Entity(tableName = "attempt_logs")
data class AttemptLogEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val lessonId: String,
    val skillId: String,
    val questionId: String,
    val interactionType: String,
    val isCorrect: Boolean,
    val misconceptionCode: String?,
    val hintsUsed: Int,
    val responseTimeMs: Long,
    val timestampEpochMs: Long = System.currentTimeMillis()
)

@Entity(tableName = "lesson_progress")
data class LessonProgressEntity(
    @PrimaryKey val lessonId: String,
    val currentQuestionIndex: Int = 0,
    val totalQuestionsCount: Int = 0,
    val practiceAnsweredCount: Int = 0,
    val practiceCorrectCount: Int = 0,
    val examplesViewed: Boolean = false,
    val guidedCompleted: Boolean = false,
    val assessmentScorePercent: Int = 0,
    val assessmentPassed: Boolean = false,
    val completed: Boolean = false,
    val starsEarned: Int = 0,
    val lastVisitedEpochMs: Long = System.currentTimeMillis()
)

@Entity(tableName = "review_queue")
data class ReviewQueueEntity(
    @PrimaryKey val skillId: String,
    val lessonId: String,
    val dueEpochMs: Long,
    val priorityReasonFa: String
)

@Entity(tableName = "achievements")
data class AchievementEntity(
    @PrimaryKey val achievementId: String,
    val titleFa: String,
    val unlockedAtEpochMs: Long
)

@Entity(tableName = "learning_sessions")
data class LearningSessionEntity(
    @PrimaryKey(autoGenerate = true) val sessionId: Long = 0,
    val startedAtEpochMs: Long,
    val endedAtEpochMs: Long? = null,
    val questionsAnswered: Int = 0
)

@Dao
interface RiaziDao {
    @Query("SELECT * FROM skill_mastery ORDER BY lessonId ASC")
    fun observeAllMastery(): Flow<List<SkillMasteryEntity>>

    @Query("SELECT * FROM skill_mastery WHERE skillId = :skillId")
    suspend fun getSkillMastery(skillId: String): SkillMasteryEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertSkillMastery(entity: SkillMasteryEntity)

    @Insert
    suspend fun insertAttemptLog(log: AttemptLogEntity)

    @Query("SELECT * FROM lesson_progress ORDER BY lessonId ASC")
    fun observeLessonProgress(): Flow<List<LessonProgressEntity>>

    @Query("SELECT * FROM lesson_progress WHERE lessonId = :lessonId")
    suspend fun getLessonProgress(lessonId: String): LessonProgressEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertLessonProgress(progress: LessonProgressEntity)

    @Query("SELECT * FROM review_queue WHERE dueEpochMs <= :nowMs ORDER BY dueEpochMs ASC")
    fun observeDueReviews(nowMs: Long): Flow<List<ReviewQueueEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertReviewQueue(item: ReviewQueueEntity)

    @Query("SELECT * FROM achievements ORDER BY unlockedAtEpochMs DESC")
    fun observeAchievements(): Flow<List<AchievementEntity>>

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAchievement(achievement: AchievementEntity)

    @Insert
    suspend fun insertSession(session: LearningSessionEntity): Long

    @Transaction
    suspend fun recordAttemptTransaction(
        mastery: SkillMasteryEntity,
        log: AttemptLogEntity,
        reviewItem: ReviewQueueEntity,
        achievement: AchievementEntity?
    ) {
        upsertSkillMastery(mastery)
        insertAttemptLog(log)
        upsertReviewQueue(reviewItem)
        if (achievement != null) {
            insertAchievement(achievement)
        }
    }

    @Query("DELETE FROM skill_mastery")
    suspend fun clearAllMastery()

    @Query("DELETE FROM attempt_logs")
    suspend fun clearAllAttemptLogs()

    @Query("DELETE FROM lesson_progress")
    suspend fun clearAllLessonProgress()

    @Query("DELETE FROM review_queue")
    suspend fun clearAllReviews()

    @Query("DELETE FROM achievements")
    suspend fun clearAllAchievements()

    @Transaction
    suspend fun resetAllChildData() {
        clearAllMastery()
        clearAllAttemptLogs()
        clearAllLessonProgress()
        clearAllReviews()
        clearAllAchievements()
    }
}

val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("CREATE TABLE IF NOT EXISTS `review_queue` (`skillId` TEXT NOT NULL, `lessonId` TEXT NOT NULL, `dueEpochMs` INTEGER NOT NULL, `priorityReasonFa` TEXT NOT NULL, PRIMARY KEY(`skillId`))")
        db.execSQL("CREATE TABLE IF NOT EXISTS `achievements` (`achievementId` TEXT NOT NULL, `titleFa` TEXT NOT NULL, `unlockedAtEpochMs` INTEGER NOT NULL, PRIMARY KEY(`achievementId`))")
        db.execSQL("CREATE TABLE IF NOT EXISTS `learning_sessions` (`sessionId` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `startedAtEpochMs` INTEGER NOT NULL, `endedAtEpochMs` INTEGER, `questionsAnswered` INTEGER NOT NULL)")
    }
}

val MIGRATION_2_3 = object : Migration(2, 3) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE `skill_mastery` ADD COLUMN `repetitionCount` INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE `lesson_progress` ADD COLUMN `totalQuestionsCount` INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE `lesson_progress` ADD COLUMN `practiceAnsweredCount` INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE `lesson_progress` ADD COLUMN `practiceCorrectCount` INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE `lesson_progress` ADD COLUMN `guidedCompleted` INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE `lesson_progress` ADD COLUMN `assessmentScorePercent` INTEGER NOT NULL DEFAULT 0")
    }
}

@Database(
    entities = [
        SkillMasteryEntity::class,
        AttemptLogEntity::class,
        LessonProgressEntity::class,
        ReviewQueueEntity::class,
        AchievementEntity::class,
        LearningSessionEntity::class
    ],
    version = 3,
    exportSchema = false
)
abstract class RiaziDatabase : RoomDatabase() {
    abstract fun riaziDao(): RiaziDao
}
