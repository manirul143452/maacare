// ============================================================
//  Pregnancy Data – MaaCare
// ============================================================

const Map<int, Map<String, String>> weeklyPregnancyData = {
  1: {
    'title': 'The Journey Begins',
    'size': 'Conception has not yet occurred.',
    'development': 'It might seem strange, but your pregnancy journey is considered to start on the first day of your last menstrual period (LMP). This is because it\'s nearly impossible to know the exact moment of conception. During this week, your body is shedding its uterine lining from the previous cycle and preparing a new, mature egg for ovulation.',
    'advice': 'Even though you\'re not officially pregnant yet, this is the most critical time to prepare your body. Start taking prenatal vitamins containing at least 400mcg of folic acid. Focus on a balanced diet, reduce stress, and avoid alcohol and smoking.',
  },
  2: {
    'title': 'Preparing for Ovulation',
    'size': 'An egg is maturing.',
    'development': 'Your body is preparing to release an egg (ovulation). The lining of your uterus is thickening to prepare for a fertilized egg. Conception typically occurs at the end of this week.',
    'advice': 'Continue with your healthy habits. Understanding your cycle can be helpful if you are trying to conceive. This is a week of hopeful anticipation.',
  },
  3: {
    'title': 'Fertilization',
    'size': 'A tiny group of cells (blastocyst).',
    'development': 'Success! A single sperm has fertilized the egg, creating a zygote. This tiny ball of cells, called a blastocyst, travels down the fallopian tube to the uterus for implantation.',
    'advice': 'You will not feel any different yet, but a miracle is happening inside you. It is crucial to avoid alcohol and smoking as your baby begins its earliest stage of development.',
  },
  4: {
    'title': 'Implantation',
    'size': 'Size of a poppy seed. / 0.04 in',
    'development': 'The blastocyst has burrowed into your uterine lining. It has divided into two parts: one becomes the embryo, and the other forms the placenta, which will nourish your baby.',
    'advice': 'You may get a positive pregnancy test this week! It’s normal to feel a mix of excitement and nervousness. Continue taking your prenatal vitamins with folic acid.',
  },
  5: {
    'title': 'Heart Begins to Beat',
    'size': 'Size of a sesame seed. / 0.12 in',
    'development': 'The major organs, including the brain, spinal cord, and heart, are beginning to form. The tiny heart starts to beat, though it may be too early to hear on an ultrasound.',
    'advice': 'You might start to feel early pregnancy symptoms like fatigue and tender breasts. Listen to your body and rest when you need to. Hydration is very important.',
  },
  6: {
    'title': 'Facial Features Form',
    'size': 'Size of a lentil. / 0.24 in',
    'development': 'Facial features are taking shape. Dark spots mark where the eyes and nostrils will be. Small folds of skin are forming the ears. Tiny buds that will become arms and legs are visible.',
    'advice': 'Morning sickness may start this week. Try eating small, frequent meals. Ginger or lemon may help soothe your stomach. Schedule your first prenatal appointment.',
  },
  7: {
    'title': 'Limb Development',
    'size': 'Size of a blueberry. / 0.51 in / 0.004 lbs',
    'development': 'The arm and leg buds are growing longer. The hands and feet look like small paddles. The brain is developing rapidly, generating about one hundred new brain cells every minute.',
    'advice': 'Food cravings and aversions are common. Try to focus on healthy options, but don\'t be too hard on yourself. Wear a comfortable, supportive bra.',
  },
  8: {
    'title': 'Tiny Movements Begin',
    'size': 'Size of a raspberry. / 0.63 in / 0.009 lbs',
    'development': 'Your baby is starting to look more human! Fingers and toes are forming. The lungs are developing. The baby is making small, jerky movements, though you won’t feel them yet.',
    'advice': 'Your first prenatal visit is likely around this time, where you might see the baby and hear the heartbeat via ultrasound for the first time. It is an emotional and reassuring moment.',
  },
  9: {
    'title': 'Details Emerge',
    'size': 'Size of a grape. / 0.9 in / 0.015 lbs',
    'development': 'The essential parts of the eye—the cornea, iris, pupil, and retina—are all starting to develop. Tiny taste buds are forming on the tongue. The embryonic "tail" has disappeared.',
    'advice': 'Fatigue can be intense as your body is working hard to build the placenta. Prioritize rest. A short nap can make a big difference. Stay hydrated.',
  },
  10: {
    'title': 'Now a Fetus',
    'size': 'Size of a prune. / 1.22 in / 0.022 lbs',
    'development': 'The embryonic period ends, and the fetal period begins. All essential organs have formed and are starting to function. Fingernails and toenails are beginning to grow.',
    'advice': 'You may start to see a tiny baby bump. Your uterus has grown to the size of a grapefruit. Talk to your doctor about genetic screening options if you are interested.',
  },
  11: {
    'title': 'Stretching and Kicking',
    'size': 'Size of a fig. / 1.61 in / 0.033 lbs',
    'development': 'The baby is very active, though you still can’t feel it. They are kicking, stretching, and even hiccuping. The diaphragm is forming, which is essential for breathing.',
    'advice': 'Headaches can be common. Make sure you are drinking enough water. Acetaminophen is generally considered safe, but always check with your doctor first.',
  },
  12: {
    'title': 'End of First Trimester',
    'size': 'Size of a lime. / 2.13 in / 0.05 lbs',
    'development': 'The critical development period is over. The baby’s reflexes are developing; their fingers will open and close. The risk of miscarriage drops significantly after this week.',
    'advice': 'Congratulations on reaching the end of the first trimester! You might start feeling more energetic. It\'s a good time to share your news with family and friends if you haven\'t already.',
  },
  13: {
    'title': 'Fingerprints Form',
    'size': 'Size of a peach. / 2.91 in / 0.095 lbs',
    'development': 'Unique fingerprints are forming on your baby’s tiny fingertips. If you’re having a girl, her ovaries now contain more than 2 million eggs. The baby is urinating into the amniotic fluid.',
    'advice': 'Welcome to the second trimester! Many women call this the "honeymoon period" of pregnancy as early symptoms fade. Your appetite may return, so focus on nutritious foods.',
  },
  14: {
    'title': 'Practicing Expressions',
    'size': 'Size of a lemon. / 3.42 in / 0.15 lbs',
    'development': 'Your baby can now squint, frown, and make other facial expressions. They might even be sucking their thumb! The liver and spleen are producing red blood cells.',
    'advice': 'Your belly is growing. Wearing comfortable, stretchy clothing can make a big difference. Gentle exercise like walking or swimming is great for you and the baby.',
  },
  15: {
    'title': 'Growing Fast',
    'size': 'Size of an apple. / 4.0 in / 0.25 lbs',
    'development': 'Your baby is growing rapidly and their skeleton is developing bones. They are actively moving around, swallowing amniotic fluid.',
    'advice': 'You might start to notice some weight gain. Continue eating a balanced diet and stay active with light exercises approved by your doctor.',
  },
  16: {
    'title': 'Hearing Your Voice',
    'size': 'Size of an avocado. / 4.57 in / 0.31 lbs',
    'development': 'The tiny bones in the ears are in place, meaning your baby can likely hear your voice. The legs are now longer than the arms, and the head is more erect.',
    'advice': 'Talk, sing, or read to your baby! They are starting to get familiar with your voice. You may feel your first baby flutters (quickening) between now and 20 weeks.',
  },
  17: {
    'title': 'Gaining Fat',
    'size': 'Size of a turnip. / 5.12 in / 0.42 lbs',
    'development': 'The baby is starting to put on some fat, which is important for regulating body temperature. The umbilical cord is growing stronger and thicker to provide nourishment.',
    'advice': 'Back pain can be a new symptom as your center of gravity shifts. Pay attention to your posture. Sleep on your side with a pillow between your knees for better support.',
  },
  18: {
    'title': 'Nervous System Develops',
    'size': 'Size of a bell pepper. / 5.59 in / 0.53 lbs',
    'development': 'The nerves are forming a protective covering called myelin, a crucial process for the nervous system that will continue for a year after birth. The baby is very active now.',
    'advice': 'Your mid-pregnancy ultrasound is usually scheduled between 18 and 22 weeks. This is a detailed scan to check the baby’s anatomy and you might find out the sex.',
  },
  19: {
    'title': 'Five Senses',
    'size': 'Size of an heirloom tomato. / 6.02 in / 0.66 lbs',
    'development': 'The baby’s brain is designating specialized areas for smell, taste, hearing, vision, and touch. A waxy coating called vernix caseosa is forming on the skin to protect it from amniotic fluid.',
    'advice': 'You may notice skin changes, like the linea nigra (a dark line down your belly). These are normal and usually fade after pregnancy. Moisturize your growing belly to help with itchiness.',
  },
  20: {
    'title': 'Halfway There!',
    'size': 'Length of a banana. / 10.08 in / 0.79 lbs',
    'development': 'You are at the halfway mark! The baby is swallowing more, which is good practice for the digestive system. You can likely feel their movements more regularly now.',
    'advice': 'This is a great milestone to celebrate. Start thinking about your birth preferences and looking into childbirth education classes. Communication with your partner is key.',
  },
  21: {
    'title': 'Eyebrows Appear',
    'size': 'Length of a carrot. / 10.51 in / 0.95 lbs',
    'development': 'The baby’s eyebrows and eyelids are fully developed. Their movements are becoming less random and more coordinated as their brain and muscles connect.',
    'advice': 'Leg cramps can be a problem, especially at night. Make sure you are staying hydrated and getting enough potassium. Gently stretching your calf muscles before bed can help.',
  },
  22: {
    'title': 'Looking Like a Newborn',
    'size': 'Size of a spaghetti squash. / 10.94 in / 1.1 lbs',
    'development': 'The baby now looks like a miniature newborn. Lips, eyelids, and eyebrows are more distinct. The pancreas, essential for hormone production, is developing steadily.',
    'advice': 'Your growing belly might be making you feel clumsy. Be mindful of your balance. Wear comfortable, low-heeled shoes to prevent falls and reduce back strain.',
  },
  23: {
    'title': 'Viability Milestone',
    'size': 'Length of a large mango. / 11.38 in / 1.32 lbs',
    'development': 'The baby has a chance of survival if born now, known as the age of viability. Blood vessels in the lungs are developing to prepare for breathing. They are listening to your heartbeat.',
    'advice': 'You might notice your feet are swelling. Try to elevate them when you can and avoid standing for long periods. Your doctor will monitor for signs of preeclampsia.',
  },
  24: {
    'title': 'Practicing Breathing',
    'size': 'Length of an ear of corn. / 11.81 in / 1.46 lbs',
    'development': 'The lungs are developing "branches" of the respiratory tree and cells that produce surfactant, a substance that helps air sacs inflate after birth. The baby’s face is fully formed.',
    'advice': 'Your doctor will likely test you for gestational diabetes between now and 28 weeks. It is a routine screening to keep you and the baby healthy.',
  },
  25: {
    'title': 'Responding to Your Voice',
    'size': 'Size of a head of cauliflower. / 13.62 in / 1.68 lbs',
    'development': 'The baby\'s hearing is now well-established. They can hear and may even respond with a jump or kick to familiar voices or loud noises outside the womb.',
    'advice': 'Your growing uterus is putting pressure on your back. Prenatal yoga or gentle stretches can help. A warm bath (not too hot) can also be very soothing.',
  },
  26: {
    'title': 'Inhaling and Exhaling',
    'size': 'Length of a scallion. / 14.02 in / 1.93 lbs',
    'development': 'The baby is now inhaling and exhaling small amounts of amniotic fluid, which is essential practice for breathing after birth. Their eyes are beginning to open.',
    'advice': 'Heartburn might become more frequent. Eat smaller meals, avoid spicy or acidic foods, and try not to lie down right after eating. Talk to your doctor about safe antacids.',
  },
  27: {
    'title': 'Active Brain',
    'size': 'Size of a head of lettuce. / 14.41 in / 2.2 lbs',
    'development': 'The baby’s brain is very active now. They are sleeping and waking at regular intervals, and they might have a favorite position in the womb. They can also get hiccups.',
    'advice': 'This is the last week of the second trimester! You might be feeling a mix of excitement and anxiety. Consider writing down your thoughts or talking to your partner or friends.',
  },
  28: {
    'title': 'Third Trimester',
    'size': 'Size of a large eggplant. / 14.8 in / 2.54 lbs',
    'development': 'Your baby can open and close their eyes, which now have eyelashes. The central nervous system can direct rhythmic breathing and control body temperature.',
    'advice': 'Welcome to the third trimester! Your prenatal checkups will likely become more frequent. It is a good time to start tracking your baby’s kicks daily.',
  },
  29: {
    'title': 'Getting Plump',
    'size': 'Size of a butternut squash. / 15.2 in / 2.87 lbs',
    'development': 'The baby is gaining fat, which will help them regulate their body temperature after birth. Their muscles and lungs are continuing to mature.',
    'advice': 'Shortness of breath is common as the baby presses up on your diaphragm. Practice good posture to give your lungs more room to expand. Rest when you need to.',
  },
  30: {
    'title': 'Brain Ridges and Wrinkles',
    'size': 'Size of a large cabbage. / 15.7 in / 3.0 lbs',
    'development': 'Your baby\'s brain is taking on its characteristic wrinkled appearance. These wrinkles allow for more brain tissue, essential for learning and functioning.',
    'advice': 'It might be getting harder to sleep comfortably. Use pillows to support your belly and back while sleeping on your side. Keep resting frequently.',
  },
  31: {
    'title': 'Rapid Brain Growth',
    'size': 'Size of a coconut. / 16.18 in / 3.75 lbs',
    'development': 'The baby’s brain is developing faster than ever, forming trillions of connections. They can process information and are starting to track light.',
    'advice': 'You may experience Braxton Hicks contractions, which are "practice" contractions. They are usually irregular and don’t get stronger. Stay hydrated and change positions to ease them.',
  },
  32: {
    'title': 'Getting Ready',
    'size': 'Size of a large jicama. / 16.69 in / 4.2 lbs',
    'development': 'The baby is practicing breathing, swallowing, and sucking. Their bones are fully formed but still soft. They are gaining about half a pound a week.',
    'advice': 'Your prenatal checkups are probably every two weeks now. Discuss your birth plan with your doctor or midwife. It’s a good time to pack your hospital bag!',
  },
  33: {
    'title': 'Immunity Boost',
    'size': 'Size of a pineapple. / 17.2 in / 4.63 lbs',
    'development': 'Your antibodies are being passed to your baby, giving them a kick-start to their own immune system to protect them after birth.',
    'advice': 'The baby is taking up a lot of space, which can make you feel uncomfortable. Continue to eat small, frequent meals to help with digestion and heartburn.',
  },
  34: {
    'title': 'Lungs Maturing',
    'size': 'Size of a cantaloupe. / 17.72 in / 5.07 lbs',
    'development': 'The baby\'s lungs are nearly fully developed. The vernix caseosa, the waxy coating on their skin, is getting thicker. Fingernails have reached the fingertips.',
    'advice': 'Your vision might be a bit blurry due to pregnancy hormones. It’s usually temporary, but mention it to your doctor. Rest your eyes when you can.',
  },
  35: {
    'title': 'Less Room to Move',
    'size': 'Size of a honeydew melon. / 18.19 in / 5.51 lbs',
    'development': 'It’s getting snug in the womb! While the baby is still active, you might notice the movements feel more like rolls and stretches rather than sharp kicks.',
    'advice': 'Your doctor may check to see if the baby has settled into a head-down position. Your visits will likely switch to weekly from now on. Keep tracking those movements!',
  },
  36: {
    'title': 'Dropping Down',
    'size': 'Size of a romaine lettuce. / 18.6 in / 5.7 lbs',
    'development': 'Baby\'s organs are mostly ready for the outside world. Your baby might “drop” lower into your pelvis, preparing for birth.',
    'advice': 'You may notice slightly easier breathing but more pressure on your bladder. Finalize your route to the hospital and make sure your car seat is installed.',
  },
  37: {
    'title': 'Full Term!',
    'size': 'Length of a bunch of Swiss chard. / 19.13 in / 6.39 lbs',
    'development': 'Congratulations, your baby is officially considered "early term." All organs are ready to function on their own. They are practicing for the big day by sucking and swallowing.',
    'advice': 'Look for signs of early labor, like losing your mucus plug or regular contractions. Don’t hesitate to call your doctor if you think you’re in labor. The waiting game begins!',
  },
  38: {
    'title': 'Grasping Reflex',
    'size': 'Length of a leek. / 19.6 in / 6.8 lbs',
    'development': 'Your baby is shedding their lanugo (fine hair) and vernix coating. They have a firm grasp which you’ll soon feel when they hold your finger!',
    'advice': 'Rest as much as possible. Keep an eye out for signs like your water breaking or rhythmic contractions. Breathe and stay calm.',
  },
  39: {
    'title': 'Ready for Birth',
    'size': 'Size of a mini watermelon. / 19.96 in / 7.28 lbs',
    'development': 'The baby is now considered "full term" and is fully prepared for birth. They have enough fat to help them regulate their body temperature in the outside world.',
    'advice': 'Your body is getting ready. You might feel more pelvic pressure or cramping. Try to stay patient and trust your body. Your baby will be here very soon!',
  },
  40: {
    'title': 'Due Date!',
    'size': 'Size of a small pumpkin. / 20.16 in / 7.72 lbs',
    'development': 'Your baby has arrived or is about to! They are perfectly designed for life outside the womb. They have a firm grasp and have stored fat to help them after birth.',
    'advice': 'Congratulations, you’ve made it to your due date! Don’t worry if you go past it; it’s very common. Rest, walk, and wait for labor to begin. Your life is about to change forever.',
  },
};

Map<String, String>? getPregnancyInfoForWeek(int week) {
  final cleanWeek = week.clamp(1, 40);
  return weeklyPregnancyData[cleanWeek];
}
